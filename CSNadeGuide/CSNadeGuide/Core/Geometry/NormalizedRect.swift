import CoreGraphics
import Foundation

/// A crop rectangle in normalized 0..1 space, independent of pixel size.
/// Origin is top-left. The editor writes these numbers, display re-applies them.
///
/// `nonisolated` because it's pure data persisted by SwiftData off the main
/// actor; the project defaults types to `@MainActor`, which its `Codable`
/// conformance must opt out of.
nonisolated struct NormalizedRect: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let full = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Build from a concrete rect measured inside `bounds` (e.g. the fitted image frame).
    init(rect: CGRect, in bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else {
            self = .full
            return
        }
        self.x = Double((rect.minX - bounds.minX) / bounds.width)
        self.y = Double((rect.minY - bounds.minY) / bounds.height)
        self.width = Double(rect.width / bounds.width)
        self.height = Double(rect.height / bounds.height)
    }

    /// Map back into a concrete rect inside `bounds`.
    func rect(in bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.minX + CGFloat(x) * bounds.width,
            y: bounds.minY + CGFloat(y) * bounds.height,
            width: CGFloat(width) * bounds.width,
            height: CGFloat(height) * bounds.height
        )
    }

    /// Clamp inside the unit square and keep a minimum size so the crop never collapses.
    func clamped(minSize: Double = 0.05) -> NormalizedRect {
        var w = min(max(width, minSize), 1)
        var h = min(max(height, minSize), 1)
        let nx = min(max(x, 0), 1 - w)
        let ny = min(max(y, 0), 1 - h)
        if nx + w > 1 { w = 1 - nx }
        if ny + h > 1 { h = 1 - ny }
        return NormalizedRect(x: nx, y: ny, width: w, height: h)
    }
}
