import SwiftUI
import SwiftData

@main
struct CSNadeGuideApp: App {
    /// Built once and shared. `AppStore` owns the CloudKit-vs-local decision.
    let container: ModelContainer
    @State private var auth = AuthService()
    @State private var shareService = ShareService()

    init() {
        container = AppStore.makeContainer()
        #if DEBUG
        // Dev fixtures win over seeding: if they populate the store, the
        // seeder sees a non-empty store and skips.
        SampleData.insertIfRequested(into: container)
        #endif
        SeedThrows.seedIfNeeded(into: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
        .environment(auth)
        .environment(shareService)
    }
}
