import SwiftUI

/// Horizontally scrolling filter chips: maps (active duty first), sides, then
/// types. One selection per group, tap again to clear; groups AND together.
struct FilterChipsRow: View {
    @Binding var filter: LibraryFilter

    private var maps: [GameMap] {
        GameMap.allCases.filter(\.isActiveDuty) + GameMap.allCases.filter { !$0.isActiveDuty }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.gapSmall) {
                ForEach(maps) { map in
                    Chip(
                        label: map.displayName.uppercased(),
                        isSelected: filter.map == map
                    ) {
                        filter.map = filter.map == map ? nil : map
                    }
                }
                ForEach(Side.allCases) { side in
                    Chip(
                        label: side.rawValue,
                        textColor: Theme.sideColor(side),
                        isSelected: filter.side == side
                    ) {
                        filter.side = filter.side == side ? nil : side
                    }
                }
                ForEach(NadeType.allCases) { type in
                    Chip(
                        label: type.displayName.uppercased(),
                        dot: Theme.typeDotColor(type),
                        isSelected: filter.type == type
                    ) {
                        filter.type = filter.type == type ? nil : type
                    }
                }
            }
        }
        .contentMargins(.horizontal, Theme.margin, for: .scrollContent)
    }
}

private struct Chip: View {
    let label: String
    var textColor: Color = Theme.textSecondary
    var dot: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dot {
                    // Near-black when selected, like all chip foreground content
                    // — the molly dot is the accent color and would vanish on
                    // the accent background otherwise.
                    Circle()
                        .fill(isSelected ? Theme.bg : dot)
                        .frame(width: 7, height: 7)
                }
                Text(label)
                    .font(Theme.mono(12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Theme.bg : textColor)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(
                isSelected ? Theme.accent : Theme.surface,
                in: RoundedRectangle(cornerRadius: Theme.radiusControl)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: Theme.radiusControl)
                        .stroke(Theme.hairline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
