import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

/// Session state + sign-in flows behind one facade. Apple is primary; Google
/// slots in next behind the same surface, Steam in v2 — call sites never
/// change. Login only ever gates share/import, never the library.
@MainActor
@Observable
final class AuthService {
    enum AuthError: LocalizedError {
        case notConfigured
        case missingToken

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Sharing isn't set up in this build yet."
            case .missingToken: "Apple didn't return an identity token."
            }
        }
    }

    private(set) var session: Session?

    var isSignedIn: Bool { session != nil }
    var userID: UUID? { session?.user.id }

    private var stateTask: Task<Void, Never>?

    init() {
        stateTask = Task { [weak self] in
            guard let client = SupabaseClientProvider.client else { return }
            self?.session = try? await client.auth.session
            for await change in client.auth.authStateChanges {
                guard !Task.isCancelled else { break }
                self?.session = change.session
            }
        }
    }

    /// Completes a native Sign in with Apple authorization against Supabase.
    /// `rawNonce` must be the value whose SHA256 was handed to Apple.
    func signInWithApple(_ authorization: ASAuthorization, rawNonce: String) async throws {
        guard let client = SupabaseClientProvider.client else { throw AuthError.notConfigured }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { throw AuthError.missingToken }

        session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
    }

    func signOut() async throws {
        guard let client = SupabaseClientProvider.client else { throw AuthError.notConfigured }
        try await client.auth.signOut()
        session = nil
    }

    // MARK: Nonce (Apple and Supabase must see matching values)

    /// Cryptographically random nonce. Hand `sha256(nonce)` to Apple and the
    /// raw value to Supabase, which checks it against the token's claim.
    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        while result.count < length {
            var random: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess else { continue }
            if random < charset.count {
                result.append(charset[Int(random)])
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
