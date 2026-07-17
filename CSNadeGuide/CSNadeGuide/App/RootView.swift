import SwiftUI

/// Placeholder root for the M1.1 skeleton. The Library (M1.3) replaces this as
/// the app's home once feature work begins.
struct RootView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(.tint)
                Text("CS2 Nade Guide")
                    .font(.title2.weight(.bold))
                Text("Skeleton building. Library lands next (M1.3).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RootView()
}
