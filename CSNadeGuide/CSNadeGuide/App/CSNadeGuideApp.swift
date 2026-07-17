import SwiftUI
import SwiftData

@main
struct CSNadeGuideApp: App {
    /// Built once and shared. `AppStore` owns the CloudKit-vs-local decision.
    let container = AppStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
