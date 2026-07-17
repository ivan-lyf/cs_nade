import SwiftUI

/// The aim-reticle mark drawn as pure shapes: a ring, four crosshair ticks
/// extending past it, and a center dot. Doubles as the app's identity mark at
/// small sizes; the editor and detail reticles are larger styled variants of
/// the same geometry.
struct ReticleMark: View {
    var size: CGFloat = 30
    var color: Color = Theme.accent
    var lineWidth: CGFloat = 2
    /// Tick length as a fraction of `size`. The detail reticle uses 0.2 to
    /// match the mock's 12pt ticks at 60pt; the identity mark keeps 0.28.
    var tickRatio: CGFloat = 0.28

    var body: some View {
        let tick = size * tickRatio
        ZStack {
            Circle()
                .stroke(color, lineWidth: lineWidth)
                .frame(width: size * 0.7, height: size * 0.7)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: lineWidth, height: tick)
                    .offset(y: -(size - tick) / 2)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            Circle()
                .fill(color)
                .frame(width: lineWidth * 1.6, height: lineWidth * 1.6)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Theme.bg
        ReticleMark(size: 44)
    }
}
