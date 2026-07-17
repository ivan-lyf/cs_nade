import Foundation
import Observation
import Supabase
import SwiftData

/// Share-out and import-in for individual tactics. This is the only place the
/// app's content touches the backend, and only ever one explicitly shared
/// throw at a time — the library itself never syncs here (the guardrail).
@MainActor
@Observable
final class ShareService {
    enum ShareError: LocalizedError {
        case notConfigured
        case notSignedIn
        case notFound
        case network

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Sharing isn't set up in this build yet."
            case .notSignedIn: "Sign in to share lineups."
            case .notFound: "That shared lineup no longer exists."
            case .network: "Couldn't reach the sharing service. Check your connection and try again."
            }
        }
    }

    /// Same-session re-shares reuse the first link instead of re-uploading.
    private var sessionShareURLs: [PersistentIdentifier: URL] = [:]

    /// Uploads the throw's images, inserts the row, returns the share URL.
    /// Failed attempts clean up any objects they already uploaded so the
    /// public bucket doesn't accumulate orphans.
    func share(_ item: Throw, userID: UUID) async throws -> URL {
        guard let client = SupabaseClientProvider.client else { throw ShareError.notConfigured }
        if let cached = sessionShareURLs[item.persistentModelID] { return cached }
        // Collision odds at 31^8 codes are negligible; a failed insert is
        // handled as a normal failure rather than retried.
        let code = Self.makeShortCode()

        var imagePayloads: [SharedTacticDTO.ImagePayload] = []
        var uploadedPaths: [String] = []
        do {
            for image in item.orderedImages {
                guard let data = image.imageData else { continue }
                let path = "\(userID.uuidString.lowercased())/\(code)/\(image.role.rawValue).jpg"
                try await client.storage.from("shared-images").upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg")
                )
                uploadedPaths.append(path)
                imagePayloads.append(.init(
                    role: image.role.rawValue,
                    path: path,
                    cropRect: image.cropRect,
                    aimPoint: image.aimPoint,
                    sortIndex: image.sortIndex
                ))
            }

            let row = SharedTacticRow(
                shortCode: code,
                ownerID: userID,
                map: item.map.rawValue,
                side: item.side.rawValue,
                type: item.type.rawValue,
                title: item.title,
                notes: item.notes,
                payload: SharedTacticDTO(
                    power: item.power.rawValue,
                    movement: item.movement.rawValue,
                    isBounce: item.isBounce,
                    standCallout: item.standCallout,
                    targetCallout: item.targetCallout,
                    images: imagePayloads
                )
            )
            try await client.from("shared_tactics").insert(row).execute()
        } catch {
            if !uploadedPaths.isEmpty {
                _ = try? await client.storage.from("shared-images").remove(paths: uploadedPaths)
            }
            throw ShareError.network
        }

        let url = ShareLinkBuilder.url(for: code)
        sessionShareURLs[item.persistentModelID] = url
        return url
    }

    /// A fetched tactic plus its downloaded image bytes, ready to preview/save.
    struct FetchedTactic {
        var row: SharedTacticRow
        var imageData: [String: Data]   // ImageRole rawValue → bytes
    }

    func fetch(code: String) async throws -> FetchedTactic {
        guard let client = SupabaseClientProvider.client else { throw ShareError.notConfigured }
        // limit(1) + array decode so "no such code" (empty result, a clean
        // notFound) is distinguishable from connectivity/decoding failures.
        let rows: [SharedTacticRow]
        do {
            rows = try await client.from("shared_tactics")
                .select()
                .eq("short_code", value: code)
                .limit(1)
                .execute()
                .value
        } catch {
            throw ShareError.network
        }
        guard let row = rows.first else { throw ShareError.notFound }

        // All images or none: a lineup missing its aim image is worse than a
        // retryable failure.
        var imageData: [String: Data] = [:]
        for payload in row.payload.images {
            do {
                imageData[payload.role] = try await client.storage
                    .from("shared-images")
                    .download(path: payload.path)
            } catch {
                throw ShareError.network
            }
        }
        return FetchedTactic(row: row, imageData: imageData)
    }

    /// Writes a fetched tactic into the local library as a new Throw.
    func saveToLibrary(_ tactic: FetchedTactic, context: ModelContext) throws {
        let row = tactic.row
        let item = Throw(
            map: GameMap(rawValue: row.map) ?? .dust2,
            side: Side(rawValue: row.side) ?? .t,
            type: NadeType(rawValue: row.type) ?? .smoke,
            title: row.title,
            notes: row.notes,
            power: ThrowPower(rawValue: row.payload.power) ?? .left,
            movement: ThrowMovement(rawValue: row.payload.movement) ?? .standing,
            isBounce: row.payload.isBounce,
            standCallout: row.payload.standCallout,
            targetCallout: row.payload.targetCallout
        )
        context.insert(item)
        for payload in row.payload.images {
            guard let data = tactic.imageData[payload.role],
                  let role = ImageRole(rawValue: payload.role) else { continue }
            let image = ThrowImage(
                role: role,
                imageData: data,
                cropRect: payload.cropRect,
                aimPoint: payload.aimPoint,
                sortIndex: payload.sortIndex
            )
            context.insert(image)
            image.owner = item
        }
        try context.save()
    }

    /// URL-safe 8-char code without look-alike characters (0/O, 1/l/I).
    static func makeShortCode() -> String {
        let alphabet = Array("23456789abcdefghjkmnpqrstuvwxyz")
        return String((0..<8).map { _ in alphabet.randomElement()! })
    }
}
