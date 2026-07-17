import SwiftUI

/// Grid card: the stand image full-bleed (crop applied) under a bottom scrim,
/// with the title and a compact meta row. Seeded throws carry the TEXTBOOK
/// badge so user content reads as distinct.
struct ThrowCardView: View {
    let item: Throw

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            background
            Theme.cardScrim

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.map.code)
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.textSecondary)
                    SideTag(side: item.side)
                    Circle()
                        .fill(Theme.typeDotColor(item.type))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(10)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(alignment: .topTrailing) {
            if item.isSeed {
                textbookBadge.padding(8)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        if let stand = item.image(for: .stand) {
            ThrowThumbnailView(throwImage: stand)
        } else {
            StripedPlaceholder()
        }
    }

    private var textbookBadge: some View {
        Text("TEXTBOOK")
            .font(Theme.mono(8))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Theme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
    }
}

/// Small outlined side tag (T sand / CT steel). Outlined only, never filled —
/// side colors stay small doses per the design brief.
struct SideTag: View {
    let side: Side
    var fontSize: CGFloat = 9

    var body: some View {
        Text(side.rawValue)
            .font(Theme.mono(fontSize))
            .foregroundStyle(Theme.sideColor(side))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.sideColor(side).opacity(0.4), lineWidth: 1)
            )
    }
}

/// Diagonal-striped stand-in where a throw has no stand image yet — the same
/// placeholder language the design mock uses for user screenshots.
struct StripedPlaceholder: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Theme.surface)
            )
            var x: CGFloat = -size.height
            while x < size.width {
                var line = Path()
                line.move(to: CGPoint(x: x, y: size.height))
                line.addLine(to: CGPoint(x: x + size.height, y: 0))
                context.stroke(line, with: .color(Theme.surfaceElevated), lineWidth: 6)
                x += 16
            }
        }
    }
}
