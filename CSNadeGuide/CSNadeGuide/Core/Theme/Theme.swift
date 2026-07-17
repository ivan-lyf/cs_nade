import SwiftUI

/// Design tokens from `design/README.md`. The app is dark-only by design, so
/// every value is absolute sRGB, not adaptive.
enum Theme {
    // MARK: Colors

    static let bg = Color(hex: 0x0B0C0E)
    static let surface = Color(hex: 0x16181C)
    static let surfaceElevated = Color(hex: 0x1E2127)
    static let hairline = Color(hex: 0x2A2E36)
    static let textPrimary = Color(hex: 0xF2F4F7)
    static let textSecondary = Color(hex: 0x9AA1AC)
    static let textTertiary = Color(hex: 0x5C636E)
    static let accent = Color(hex: 0xFF7A1A)
    static let accentPressed = Color(hex: 0xE86A0E)
    /// Selected-fill tint for accent-bordered selector cells.
    static let accentTint = Color(hex: 0xFF7A1A).opacity(0.14)
    static let success = Color(hex: 0x3FB27F)
    static let warning = Color(hex: 0xC9A227)

    /// Side coding, used as small outlined tags only — never fills.
    static func sideColor(_ side: Side) -> Color {
        switch side {
        case .t:  Color(hex: 0xC9A227)
        case .ct: Color(hex: 0x5B8DEF)
        }
    }

    static func typeDotColor(_ type: NadeType) -> Color {
        switch type {
        case .smoke: Color(hex: 0xB8BEC9)
        case .flash: Color(hex: 0xF2F4F7)
        case .molly: Color(hex: 0xFF7A1A)
        case .he:    Color(hex: 0xE8563F)
        case .decoy: Color(hex: 0x8A8F99)
        }
    }

    // MARK: Shape & spacing

    static let radiusCard: CGFloat = 14
    static let radiusControl: CGFloat = 10
    static let radiusCell: CGFloat = 8
    static let radiusTag: CGFloat = 6
    static let margin: CGFloat = 16
    static let gutter: CGFloat = 12
    static let gapSmall: CGFloat = 8

    /// Bottom scrim over card imagery: transparent through the top ~36%, then
    /// to near-black. CS2 screenshots are busy and colorful — the scrim is
    /// load-bearing for text contrast, never rely on the photo being dark.
    static var cardScrim: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.36),
                .init(color: Color(hex: 0x0B0C0E).opacity(0.92), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// SF Mono, the face for all metadata: map codes, tags, coordinates,
    /// section labels.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    /// Absolute sRGB from a 0xRRGGBB literal.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
