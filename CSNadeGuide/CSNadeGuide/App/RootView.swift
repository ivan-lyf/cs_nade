import SwiftUI
import SwiftData

/// App root: the Library inside the navigation stack. The app is dark-only —
/// `preferredColorScheme` backs up the Info.plist Dark style so previews and
/// sheets stay on-theme too.
struct RootView: View {
    var body: some View {
        NavigationStack {
            LibraryView()
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .modelContainer(AppStore.makeContainer(inMemory: true))
}
