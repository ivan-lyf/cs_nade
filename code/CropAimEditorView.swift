import SwiftUI
import UIKit

/// Foundation implementation of the crop + aim editor.
///
/// Design choices that keep the math honest:
///  - Everything normalizes against the *fitted image frame* (the rect the
///    image occupies aspect-fit at zoom 1). Zoom/pan are viewing aids only.
///  - Handle and reticle drags use gesture *translation* divided by the current
///    zoom scale, so we never need to invert an absolute transform.
///  - Outputs are pure values: a NormalizedRect and an optional NormalizedPoint.
///
/// Left to tune on device: pinch focal point, momentum, and double-tap-to-fit.
struct CropAimEditorView: View {
    let image: UIImage
    @Binding var cropRect: NormalizedRect
    @Binding var aimPoint: NormalizedPoint?
    var allowsAim: Bool = true

    enum Tool: String, CaseIterable { case crop = "Crop", aim = "Aim" }
    @State private var tool: Tool = .crop

    // Viewing transform
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var basePan: CGSize = .zero

    // Drag bookkeeping (content-space start values)
    @State private var startRect: CGRect = .zero
    @State private var startAim: CGPoint = .zero

    private let handleSize: CGFloat = 28
    private let snapTolerance: Double = 0.02
    private let snapTargets: [Double] = [0, 1.0 / 3.0, 0.5, 2.0 / 3.0, 1]
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private enum Corner { case tl, tr, bl, br }

    var body: some View {
        GeometryReader { geo in
            let fitted = Self.fittedFrame(imageSize: image.size, in: geo.size)
            let cr = cropRect.clamped().rect(in: fitted)

            ZStack {
                Color.black.ignoresSafeArea()

                content(fitted: fitted, cr: cr)
                    .scaleEffect(scale, anchor: .center)
                    .offset(pan)
                    .gesture(zoomGesture)
            }
            .overlay(alignment: .bottom) { toolbar }
        }
    }

    // MARK: Content (image + overlays share one coordinate space)

    private func content(fitted: CGRect, cr: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

            dimming(cr: cr)
            cropBorder(cr: cr)
            corners(fitted: fitted, cr: cr)
            if allowsAim { reticle(fitted: fitted) }
        }
        // Background pan when the user drags empty space
        .simultaneousGesture(panGesture)
        // Placing the aim marker by tapping while in Aim mode
        .simultaneousGesture(aimPlaceGesture(fitted: fitted), including: tool == .aim ? .all : .subviews)
    }

    // MARK: Overlays

    private func dimming(cr: CGRect) -> some View {
        Rectangle()
            .fill(.black.opacity(0.55))
            .reverseMask { Rectangle().path(in: cr) }
            .allowsHitTesting(false)
    }

    private func cropBorder(cr: CGRect) -> some View {
        Rectangle()
            .stroke(Color.accentColor, lineWidth: 1.5)
            .frame(width: cr.width, height: cr.height)
            .position(x: cr.midX, y: cr.midY)
            .allowsHitTesting(false)
    }

    private func corners(fitted: CGRect, cr: CGRect) -> some View {
        ForEach([Corner.tl, .tr, .bl, .br], id: \.self) { corner in
            handle
                .position(cornerPoint(corner, in: cr))
                .highPriorityGesture(cornerDrag(corner, fitted: fitted))
                .opacity(tool == .crop ? 1 : 0.25)
                .allowsHitTesting(tool == .crop)
        }
    }

    private var handle: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(.black.opacity(0.4), lineWidth: 1))
            .shadow(radius: 2)
    }

    private func reticle(fitted: CGRect) -> some View {
        let p = (aimPoint ?? .center).point(in: fitted)
        return ZStack {
            Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 40, height: 40)
            Rectangle().fill(Color.accentColor).frame(width: 2, height: 22)
            Rectangle().fill(Color.accentColor).frame(width: 22, height: 2)
        }
        .position(p)
        .highPriorityGesture(reticleDrag(fitted: fitted))
        .opacity(tool == .aim ? 1 : 0.4)
        .allowsHitTesting(tool == .aim)
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            ForEach(Tool.allCases, id: \.self) { t in
                if t == .aim && !allowsAim { EmptyView() }
                else {
                    Button(t.rawValue) { tool = t }
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(tool == t ? Color.accentColor : Color.white.opacity(0.1),
                                    in: Capsule())
                        .foregroundStyle(tool == t ? .black : .white)
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: Gestures

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale = min(max(baseScale * $0, 1), 6) }
            .onEnded { _ in baseScale = scale }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { pan = CGSize(width: basePan.width + $0.translation.width,
                                      height: basePan.height + $0.translation.height) }
            .onEnded { _ in basePan = pan }
    }

    private func aimPlaceGesture(fitted: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                guard tool == .aim else { return }
                let np = NormalizedPoint(point: value.location, in: fitted).clamped()
                aimPoint = snap(np)
            }
    }

    private func cornerDrag(_ corner: Corner, fitted: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == .zero { startRect = cropRect.clamped().rect(in: fitted) }
                let dx = value.translation.width / scale
                let dy = value.translation.height / scale
                var r = startRect
                switch corner {
                case .tl: r.origin.x += dx; r.origin.y += dy; r.size.width -= dx; r.size.height -= dy
                case .tr: r.origin.y += dy; r.size.width += dx; r.size.height -= dy
                case .bl: r.origin.x += dx; r.size.width -= dx; r.size.height += dy
                case .br: r.size.width += dx; r.size.height += dy
                }
                let normalized = NormalizedRect(rect: r.standardized, in: fitted)
                cropRect = snap(normalized).clamped()
            }
            .onEnded { _ in startRect = .zero }
    }

    private func reticleDrag(fitted: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if startAim == .zero { startAim = (aimPoint ?? .center).point(in: fitted) }
                let moved = CGPoint(x: startAim.x + value.translation.width / scale,
                                    y: startAim.y + value.translation.height / scale)
                aimPoint = snap(NormalizedPoint(point: moved, in: fitted).clamped())
            }
            .onEnded { _ in startAim = .zero }
    }

    // MARK: Snapping (with haptic on engage)

    private func snap(_ v: Double) -> Double {
        for t in snapTargets where abs(v - t) < snapTolerance {
            if abs(v - t) > 0.001 { haptic.impactOccurred(intensity: 0.5) }
            return t
        }
        return v
    }

    private func snap(_ p: NormalizedPoint) -> NormalizedPoint {
        NormalizedPoint(x: snap(p.x), y: snap(p.y))
    }

    private func snap(_ r: NormalizedRect) -> NormalizedRect {
        NormalizedRect(x: snap(r.x), y: snap(r.y), width: r.width, height: r.height)
    }

    // MARK: Geometry helpers

    private func cornerPoint(_ c: Corner, in r: CGRect) -> CGPoint {
        switch c {
        case .tl: CGPoint(x: r.minX, y: r.minY)
        case .tr: CGPoint(x: r.maxX, y: r.minY)
        case .bl: CGPoint(x: r.minX, y: r.maxY)
        case .br: CGPoint(x: r.maxX, y: r.maxY)
        }
    }

    /// The rect the image occupies when aspect-fit in `container` at zoom 1.
    static func fittedFrame(imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: container)
        }
        let s = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * s, height: imageSize.height * s)
        let origin = CGPoint(x: (container.width - size.width) / 2,
                             y: (container.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }
}

// Punch a hole in a shape so the crop window reads through the dimming layer.
private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(mask().blendMode(.destinationOut))
                .compositingGroup()
        }
    }
}
