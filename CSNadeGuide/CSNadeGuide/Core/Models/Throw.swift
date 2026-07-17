import Foundation
import SwiftData

/// One nade throw. Source of truth lives here on-device; CloudKit mirrors it.
///
/// CloudKit rules honored: every stored property has a default, the
/// relationship is optional, and there are no unique constraints.
@Model
final class Throw {
    var id: UUID = UUID()
    var map: GameMap = GameMap.dust2
    var side: Side = Side.t
    var type: NadeType = NadeType.smoke
    var title: String = ""
    var notes: String = ""

    // Technique (CS2_TERMS §5). Power and movement are independent choices.
    var power: ThrowPower = ThrowPower.left
    var movement: ThrowMovement = ThrowMovement.standing
    /// Bank/wall bounce flag layered on top of the power+movement combo.
    var isBounce: Bool = false

    // Location, split to match the stand-image / aim-image pairing. Both are
    // drawn from the map's callout list (see `Callouts`).
    var standCallout: String = ""
    var targetCallout: String = ""

    /// Seeded textbook content, shown distinct from user throws.
    var isSeed: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ThrowImage.owner)
    var images: [ThrowImage]? = []

    init(
        map: GameMap = .dust2,
        side: Side = .t,
        type: NadeType = .smoke,
        title: String = "",
        notes: String = "",
        power: ThrowPower = .left,
        movement: ThrowMovement = .standing,
        isBounce: Bool = false,
        standCallout: String = "",
        targetCallout: String = "",
        isSeed: Bool = false
    ) {
        self.id = UUID()
        self.map = map
        self.side = side
        self.type = type
        self.title = title
        self.notes = notes
        self.power = power
        self.movement = movement
        self.isBounce = isBounce
        self.standCallout = standCallout
        self.targetCallout = targetCallout
        self.isSeed = isSeed
        self.createdAt = Date()
        self.updatedAt = Date()
        self.images = []
    }

    /// Images in display order.
    var orderedImages: [ThrowImage] {
        (images ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    func image(for role: ImageRole) -> ThrowImage? {
        orderedImages.first { $0.role == role }
    }

    /// A jump/run-jump lineup needs precise manual timing now that competitive
    /// jump-throw binds are banned (CS2_TERMS §1). Surfaced as a small UI note.
    var needsManualJumpthrow: Bool {
        movement == .jump || movement == .runJump
    }

    /// Compact technique label for meta tags, e.g. "JUMP·L" or "STAND·L+R".
    var techniqueCode: String {
        "\(movement.code)·\(power.code)"
    }

    func touch() {
        updatedAt = Date()
    }
}
