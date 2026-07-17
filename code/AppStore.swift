import SwiftData

/// Builds the app's SwiftData container.
///
/// Requirements on the app target for `.automatic` CloudKit sync:
///  - iCloud capability with CloudKit enabled
///  - a CloudKit container id
///  - Background Modes > Remote notifications
///  - all @Model properties keep defaults / optionals (already done)
enum AppStore {
    @MainActor
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([Throw.self, ThrowImage.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
