import SwiftUI
import UIKit

/// Full-screen chrome around the editor canvas: floating Cancel (left) and
/// Done (right) over the full-bleed image, per design §3. Works on local
/// copies of the values and only commits through `onDone`.
struct CropAimEditorScreen: View {
    let image: UIImage
    let allowsAim: Bool
    let onDone: (NormalizedRect, NormalizedPoint?) -> Void
    let onCancel: (() -> Void)?

    @State private var cropRect: NormalizedRect
    @State private var aimPoint: NormalizedPoint?
    @Environment(\.dismiss) private var dismiss

    init(
        image: UIImage,
        cropRect: NormalizedRect,
        aimPoint: NormalizedPoint?,
        allowsAim: Bool,
        onDone: @escaping (NormalizedRect, NormalizedPoint?) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.image = image
        self.allowsAim = allowsAim
        self.onDone = onDone
        self.onCancel = onCancel
        _cropRect = State(initialValue: cropRect)
        _aimPoint = State(initialValue: aimPoint)
    }

    var body: some View {
        ZStack(alignment: .top) {
            CropAimEditorView(
                image: image,
                cropRect: $cropRect,
                aimPoint: $aimPoint,
                allowsAim: allowsAim
            )

            HStack {
                Button("Cancel") {
                    onCancel?()
                    dismiss()
                }
                .font(.system(size: 16))
                .foregroundStyle(.white)
                Spacer()
                Button("Done") {
                    onDone(cropRect, committedAim)
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.8), radius: 4)
            .padding(.horizontal, Theme.margin)
            .padding(.top, 8)
        }
        .background(Color.black.ignoresSafeArea())
    }

    /// An aim image always carries a visible marker: default to the crop's
    /// center when none was placed, and clamp a placed marker into the crop so
    /// it can't silently vanish from the detail view.
    private var committedAim: NormalizedPoint? {
        guard allowsAim else { return aimPoint }
        let crop = cropRect.clamped()
        let cropCenter = NormalizedPoint(
            x: crop.x + crop.width / 2,
            y: crop.y + crop.height / 2
        )
        guard let aim = aimPoint else { return cropCenter }
        return NormalizedPoint(
            x: min(max(aim.x, crop.x), crop.x + crop.width),
            y: min(max(aim.y, crop.y), crop.y + crop.height)
        )
    }
}
