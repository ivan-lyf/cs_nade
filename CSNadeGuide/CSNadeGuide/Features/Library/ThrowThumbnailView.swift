import SwiftUI
import ImageIO
import UIKit

/// Card-size rendering of a stored image: crops and downsamples off the main
/// thread and caches the bitmap, so grid scrolling never decodes full
/// screenshots. Shows the striped placeholder until the thumbnail lands.
struct ThrowThumbnailView: View {
    let throwImage: ThrowImage
    @State private var thumbnail: UIImage?

    private var cacheKey: String {
        ThumbnailStore.key(id: throwImage.id, crop: throwImage.cropRect)
    }

    var body: some View {
        GeometryReader { geo in
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    StripedPlaceholder()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .task(id: cacheKey) {
            thumbnail = await ThumbnailStore.thumbnail(
                id: throwImage.id,
                data: throwImage.imageData,
                crop: throwImage.cropRect
            )
        }
    }
}

/// In-memory thumbnail cache backed by off-main generation. Keyed by image id
/// + crop, so editing a crop naturally invalidates the old entry.
nonisolated enum ThumbnailStore {
    private static let cache = NSCache<NSString, UIImage>()
    /// Card-size default; the detail hero requests a larger budget.
    static let cardMaxDimension: CGFloat = 600

    static func key(id: UUID, crop: NormalizedRect, maxDimension: CGFloat = cardMaxDimension) -> String {
        "\(id.uuidString)-\(crop.x)-\(crop.y)-\(crop.width)-\(crop.height)-\(Int(maxDimension))"
    }

    static func thumbnail(
        id: UUID,
        data: Data?,
        crop: NormalizedRect,
        maxDimension: CGFloat = cardMaxDimension
    ) async -> UIImage? {
        guard let data else { return nil }
        let cacheKey = key(id: id, crop: crop, maxDimension: maxDimension) as NSString
        if let hit = cache.object(forKey: cacheKey) { return hit }
        let made = await Task.detached(priority: .userInitiated) {
            makeThumbnail(data: data, crop: crop, maxDimension: maxDimension)
        }.value
        if let made {
            cache.setObject(made, forKey: cacheKey)
        }
        return made
    }

    private static func makeThumbnail(
        data: Data,
        crop: NormalizedRect,
        maxDimension: CGFloat
    ) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let full = CGImageSourceCreateImageAtIndex(source, 0, options)
        else { return nil }

        let r = crop.clamped()
        let w = CGFloat(full.width)
        let h = CGFloat(full.height)
        let pixelRect = CGRect(
            x: r.x * w, y: r.y * h,
            width: r.width * w, height: r.height * h
        ).integral
        let cropped = full.cropping(to: pixelRect) ?? full

        let scale = min(1, maxDimension / CGFloat(max(cropped.width, cropped.height)))
        let target = CGSize(
            width: (CGFloat(cropped.width) * scale).rounded(.down),
            height: (CGFloat(cropped.height) * scale).rounded(.down)
        )
        guard target.width > 0, target.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
