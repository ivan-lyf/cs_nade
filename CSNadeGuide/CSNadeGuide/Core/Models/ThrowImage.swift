import Foundation
import SwiftData
import UIKit

/// One image attached to a throw: the original bytes plus a normalized crop
/// transform and an optional aim marker. We never store pre-cropped bitmaps.
@Model
final class ThrowImage {
    var id: UUID = UUID()
    var role: ImageRole = ImageRole.stand

    /// Original image bytes. `.externalStorage` keeps them on disk (and out of
    /// the row), and CloudKit syncs them as an asset.
    @Attribute(.externalStorage) var imageData: Data?

    var cropRect: NormalizedRect = NormalizedRect.full
    var aimPoint: NormalizedPoint?
    var sortIndex: Int = 0

    var owner: Throw?

    init(
        role: ImageRole,
        imageData: Data?,
        cropRect: NormalizedRect = .full,
        aimPoint: NormalizedPoint? = nil,
        sortIndex: Int = 0
    ) {
        self.id = UUID()
        self.role = role
        self.imageData = imageData
        self.cropRect = cropRect
        self.aimPoint = aimPoint
        self.sortIndex = sortIndex
    }

    /// Decoded original. Nil if bytes are missing or unreadable.
    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
}
