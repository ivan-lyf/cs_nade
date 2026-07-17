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

extension ThrowImage {
    /// The original with `cropRect` applied, for card thumbnails and heroes.
    /// Assumes `.up` orientation — the capture pipeline re-renders imports,
    /// normalizing orientation, before they are stored.
    var croppedUIImage: UIImage? {
        guard let ui = uiImage else { return nil }
        let r = cropRect.clamped()
        guard r != .full, let cg = ui.cgImage else { return ui }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let pixelRect = CGRect(
            x: r.x * w, y: r.y * h,
            width: r.width * w, height: r.height * h
        ).integral
        guard let cropped = cg.cropping(to: pixelRect) else { return ui }
        return UIImage(cgImage: cropped, scale: ui.scale, orientation: ui.imageOrientation)
    }
}
