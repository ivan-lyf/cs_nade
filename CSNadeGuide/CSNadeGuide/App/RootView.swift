import SwiftUI
import SwiftData

/// App root: the Library inside the navigation stack. The app is dark-only —
/// `preferredColorScheme` backs up the Info.plist Dark style so previews and
/// sheets stay on-theme too. Incoming share links (universal or csnade://)
/// land here and present the import sheet.
struct RootView: View {
    @State private var pendingImport: PendingImport?

    var body: some View {
        NavigationStack {
            LibraryView()
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onOpenURL { url in
            if let code = ShareLinkBuilder.code(from: url) {
                pendingImport = PendingImport(code: code)
            }
        }
        #if DEBUG
        .onAppear {
            if DebugFlags.openImport {
                pendingImport = PendingImport(code: "debug000")
            }
        }
        #endif
        .sheet(item: $pendingImport) { pending in
            ImportTacticView(code: pending.code)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(AppStore.makeContainer(inMemory: true))
}
