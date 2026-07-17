import Foundation

/// Codable payload for one shared tactic: everything needed to reconstruct a
/// Throw on the receiving device. Stored as `shared_tactics.payload`; image
/// bytes live in Storage at the recorded paths.
struct SharedTacticDTO: Codable {
    struct ImagePayload: Codable {
        var role: String
        var path: String
        var cropRect: NormalizedRect
        var aimPoint: NormalizedPoint?
        var sortIndex: Int
    }

    var power: String
    var movement: String
    var isBounce: Bool
    var standCallout: String
    var targetCallout: String
    var images: [ImagePayload]
}

/// One row of the `shared_tactics` table (see backend/schema.sql).
struct SharedTacticRow: Codable {
    var shortCode: String
    var ownerID: UUID
    var map: String
    var side: String
    var type: String
    var title: String
    var notes: String
    var payload: SharedTacticDTO

    enum CodingKeys: String, CodingKey {
        case shortCode = "short_code"
        case ownerID = "owner_id"
        case map, side, type, title, notes, payload
    }
}
