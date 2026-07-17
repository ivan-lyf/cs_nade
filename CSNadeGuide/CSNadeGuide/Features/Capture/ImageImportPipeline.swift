import UIKit

/// Normalizes imported screenshots before storage: re-renders the bitmap
/// (which also bakes in any EXIF orientation), downscales so the long edge is
/// at most 2000px, and encodes JPEG at 0.8 — so CloudKit assets stay small.
/// Every image entering the store goes through here; nothing else may write
/// raw picker bytes into a ThrowImage.
enum ImageImportPipeline {
    static let maxLongEdge: CGFloat = 2000
    static let jpegQuality: CGFloat = 0.8

    static func process(data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return process(image)
    }

    static func process(_ image: UIImage) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let ratio = min(1, maxLongEdge / max(size.width, size.height))
        let target = CGSize(
            width: (size.width * ratio).rounded(.down),
            height: (size.height * ratio).rounded(.down)
        )
        guard target.width > 0, target.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: jpegQuality)
    }
}
