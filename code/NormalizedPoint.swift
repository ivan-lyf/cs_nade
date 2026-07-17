import CoreGraphics
import Foundation

/// The aim marker in normalized 0..1 space, relative to the fitted image frame.
struct NormalizedPoint: Codable, Equatable, Hashable {
    var x: Double
    var y: Double

    static let center = NormalizedPoint(x: 0.5, y: 0.5)

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(point: CGPoint, in bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else {
            self = .center
            return
        }
        self.x = Double((point.x - bounds.minX) / bounds.width)
        self.y = Double((point.y - bounds.minY) / bounds.height)
    }

    func point(in bounds: CGRect) -> CGPoint {
        CGPoint(
            x: bounds.minX + CGFloat(x) * bounds.width,
            y: bounds.minY + CGFloat(y) * bounds.height
        )
    }

    func clamped() -> NormalizedPoint {
        NormalizedPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }
}
