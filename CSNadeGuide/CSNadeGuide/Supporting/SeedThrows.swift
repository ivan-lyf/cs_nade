import Foundation
import SwiftData

/// Textbook placeholder lineups inserted once, on first launch into an empty
/// store, flagged `isSeed` so the UI badges them as distinct from user
/// content. Guarded by a UserDefaults flag — app bookkeeping, not library
/// data — so deleting them doesn't resurrect them on the next launch.
@MainActor
enum SeedThrows {
    private static let didSeedKey = "didSeedTextbookThrows.v1"

    static func seedIfNeeded(into container: ModelContainer) {
        #if DEBUG
        // QA hook: `-skip-seed` keeps the store empty (and leaves the flag
        // unset) so the empty state can be exercised.
        if ProcessInfo.processInfo.arguments.contains("-skip-seed") { return }
        #endif
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didSeedKey) else { return }

        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Throw>())) ?? 0
        if count == 0 {
            for seed in seeds {
                context.insert(seed)
            }
            do {
                try context.save()
                defaults.set(true, forKey: didSeedKey)
            } catch {
                // Leave the flag unset so seeding retries next launch instead
                // of being lost forever.
            }
        } else {
            // The store had content (e.g. a restored library): an established
            // library should never be seeded into.
            defaults.set(true, forKey: didSeedKey)
        }
    }

    private static var seeds: [Throw] {
        let note = { (body: String) in
            body + "\n\nTextbook placeholder — replace with your own screenshots and exact lineup."
        }
        return [
            Throw(map: .mirage, side: .t, type: .smoke, title: "Window from Top Mid",
                  notes: note("Blocks the sniper's nest for the mid take."),
                  power: .left, movement: .jump,
                  standCallout: "Top Mid", targetCallout: "Window", isSeed: true),
            Throw(map: .mirage, side: .t, type: .smoke, title: "CT smoke from T Ramp",
                  notes: note("Cuts the connector rotation for an A hit."),
                  power: .left, movement: .jump,
                  standCallout: "T Ramp", targetCallout: "CT", isSeed: true),
            Throw(map: .dust2, side: .t, type: .smoke, title: "Xbox from T Spawn",
                  notes: note("The classic cross smoke for the mid-to-B split."),
                  power: .left, movement: .runJump,
                  standCallout: "T Spawn", targetCallout: "Xbox", isSeed: true),
            Throw(map: .inferno, side: .t, type: .molly, title: "Coffins from Banana",
                  notes: note("Clears the coffins player before the B take."),
                  power: .left, movement: .standing,
                  standCallout: "Banana", targetCallout: "Coffins", isSeed: true),
            Throw(map: .nuke, side: .t, type: .smoke, title: "Garage from T Red",
                  notes: note("Covers the outside cross toward secret."),
                  power: .left, movement: .jump,
                  standCallout: "T Red", targetCallout: "Garage", isSeed: true),
            Throw(map: .overpass, side: .ct, type: .molly, title: "Monster stop molly",
                  notes: note("Delays the B rush out of the tunnel."),
                  power: .left, movement: .standing,
                  standCallout: "B Site", targetCallout: "Monster", isSeed: true),
        ]
    }
}
