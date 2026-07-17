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
        isSeed: Bool = false
    ) {
        self.id = UUID()
        self.map = map
        self.side = side
        self.type = type
        self.title = title
        self.notes = notes
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

    func touch() {
        updatedAt = Date()
    }
}
