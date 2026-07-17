import SwiftData

/// Builds the app's SwiftData container.
///
/// CloudKit backup/sync is currently OFF: the app ships local-first, and the
/// iCloud/CloudKit capability isn't enabled on the target yet (it needs a paid
/// Apple Developer Program membership). Enabling `.automatic` without that
/// entitlement fails at launch, so we keep it `.none` until then.
///
/// To turn CloudKit on later:
///  1. Add the iCloud capability (CloudKit) + a container id on the target.
///  2. Add Background Modes > Remote notifications.
///  3. Flip `cloudKit` below to `.automatic`.
/// The @Model types already follow CloudKit's rules (defaults, optionals, no
/// unique constraints), so no model changes are needed.
enum AppStore {
    private static let cloudKit: ModelConfiguration.CloudKitDatabase = .none

    @MainActor
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([Throw.self, ThrowImage.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : cloudKit
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
