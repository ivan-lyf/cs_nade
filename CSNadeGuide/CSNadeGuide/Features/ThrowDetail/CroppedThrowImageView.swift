import SwiftUI

/// Renders a `ThrowImage` purely from its stored normalized values: the
/// original with `cropRect` applied and, when asked, the aim reticle at
/// `aimPoint` — correct at any view size. Decoding happens off-main through
/// `ThumbnailStore` (hero-sized), so body evaluation never decodes JPEGs.
struct CroppedThrowImageView: View {
    let throwImage: ThrowImage
    var showsReticle: Bool = false
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    /// Hero-quality budget: 300pt hero at 3x is 900px; 1600 leaves headroom.
    private static let heroMaxDimension: CGFloat = 1600

    private var cacheKey: String {
        ThumbnailStore.key(
            id: throwImage.id,
            crop: throwImage.cropRect,
            maxDimension: Self.heroMaxDimension
        )
    }

    var body: some View {
        GeometryReader { geo in
            if let image {
                let display = Self.displayFrame(
                    imageSize: image.size,
                    container: geo.size,
                    contentMode: contentMode
                )
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: display.width, height: display.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    if showsReticle, let point = reticlePoint(display: display, container: geo.size) {
                        ReticleMark(size: 60, tickRatio: 0.2)
                            .shadow(color: Theme.accent.opacity(0.5), radius: 6)
                            .position(point)
                    }
                }
            } else {
                StripedPlaceholder()
            }
        }
        .clipped()
        .task(id: cacheKey) {
            image = await ThumbnailStore.thumbnail(
                id: throwImage.id,
                data: throwImage.imageData,
                crop: throwImage.cropRect,
                maxDimension: Self.heroMaxDimension
            )
        }
    }

    /// The frame the cropped image occupies inside `container` (centered;
    /// overflows on `.fill`, letterboxes on `.fit`).
    static func displayFrame(imageSize: CGSize, container: CGSize, contentMode: ContentMode) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0,
              container.width > 0, container.height > 0 else { return container }
        let wRatio = container.width / imageSize.width
        let hRatio = container.height / imageSize.height
        let scale = contentMode == .fill ? max(wRatio, hRatio) : min(wRatio, hRatio)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    /// Maps `aimPoint` (normalized against the *original* image) into the
    /// displayed *cropped* image's coordinate space. Nil when the marker falls
    /// outside the crop.
    private func reticlePoint(display: CGSize, container: CGSize) -> CGPoint? {
        guard let aim = throwImage.aimPoint else { return nil }
        let crop = throwImage.cropRect.clamped()
        let relX = (aim.x - crop.x) / crop.width
        let relY = (aim.y - crop.y) / crop.height
        guard (0...1).contains(relX), (0...1).contains(relY) else { return nil }
        let originX = (container.width - display.width) / 2
        let originY = (container.height - display.height) / 2
        return CGPoint(
            x: originX + CGFloat(relX) * display.width,
            y: originY + CGFloat(relY) * display.height
        )
    }
}
