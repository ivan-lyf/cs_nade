import SwiftUI

/// Centered, understated empty state: hairline ring with the reticle mark, a
/// prompt, and the accent add button.
struct EmptyLibraryView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 1)
                    .frame(width: 64, height: 64)
                ReticleMark(size: 30)
            }
            .padding(.bottom, 16)

            Text("No lineups yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)

            Text("Add your first throw with the button below.\nTextbook lineups are already loaded under each map's filter.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.bottom, 18)

            Button(action: onAdd) {
                Text("Add a throw")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ZStack {
        Theme.bg.ignoresSafeArea()
        EmptyLibraryView {}
    }
}
