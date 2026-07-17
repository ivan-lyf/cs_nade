#if DEBUG
import SwiftData
import UIKit

/// Dev-only fixtures. Launch with `-sample-data` to fill an empty store so the
/// populated Library can be exercised before real content exists. Distinct
/// from `SeedThrows` (M1.6), which ships in the product; this never runs in
/// Release builds.
@MainActor
enum SampleData {
    static let launchArgument = "-sample-data"

    static func insertIfRequested(into container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }
        let context = container.mainContext
        let existing = (try? context.fetchCount(FetchDescriptor<Throw>())) ?? 0
        guard existing == 0 else { return }

        for (index, fixture) in fixtures.enumerated() {
            let item = Throw(
                map: fixture.map,
                side: fixture.side,
                type: fixture.type,
                title: fixture.title,
                notes: fixture.notes,
                power: fixture.power,
                movement: fixture.movement,
                standCallout: fixture.stand,
                targetCallout: fixture.target,
                isSeed: fixture.isSeed
            )
            context.insert(item)
            if fixture.hasImage {
                let image = ThrowImage(
                    role: .stand,
                    imageData: placeholderJPEG(index: index),
                    sortIndex: 0
                )
                item.images?.append(image)
            }
        }
        try? context.save()
    }

    private struct Fixture {
        let map: GameMap
        let side: Side
        let type: NadeType
        let title: String
        let stand: String
        let target: String
        let power: ThrowPower
        let movement: ThrowMovement
        let notes: String
        var isSeed = false
        var hasImage = true
    }

    private static let fixtures: [Fixture] = [
        Fixture(map: .mirage, side: .t, type: .smoke, title: "Window from Top Mid",
                stand: "Top Mid", target: "Window", power: .left, movement: .jump,
                notes: "Line up with the antenna tip. Blocks the sniper's nest for the mid take.",
                isSeed: true),
        Fixture(map: .mirage, side: .t, type: .flash, title: "Palace pop flash",
                stand: "Palace", target: "A Default", power: .right, movement: .standing,
                notes: "Underhand off the palace overhang; pops before site players can turn."),
        Fixture(map: .dust2, side: .t, type: .smoke, title: "Xbox from T Spawn",
                stand: "T Spawn", target: "Xbox", power: .left, movement: .runJump,
                notes: "Classic cross smoke. Run from the spawn barrels and release at the peak.",
                isSeed: true),
        Fixture(map: .inferno, side: .ct, type: .molly, title: "Banana stop molly",
                stand: "CT", target: "Banana", power: .left, movement: .standing,
                notes: "Cuts the early rush; bounce it off the sandbag lip.", hasImage: false),
        Fixture(map: .nuke, side: .t, type: .smoke, title: "Garage from T Red",
                stand: "T Red", target: "Garage", power: .left, movement: .jump,
                notes: "Covers the outside cross toward secret."),
        Fixture(map: .overpass, side: .ct, type: .he, title: "Monster HE",
                stand: "B Site", target: "Monster", power: .left, movement: .standing,
                notes: "Chip damage on the B rush before they exit the tunnel."),
        Fixture(map: .ancient, side: .t, type: .decoy, title: "Cave decoy fake",
                stand: "Mid", target: "Cave", power: .right, movement: .standing,
                notes: "Sells a B split while the pack takes A."),
    ]

    /// Deterministic striped placeholder, tinted per index so cards differ.
    private static func placeholderJPEG(index: Int) -> Data? {
        let size = CGSize(width: 1200, height: 800)
        let hue = CGFloat((index * 47) % 360) / 360
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            UIColor(hue: hue, saturation: 0.22, brightness: 0.22, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(hue: hue, saturation: 0.18, brightness: 0.30, alpha: 1).setStroke()
            let path = UIBezierPath()
            path.lineWidth = 22
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 64
            }
            path.stroke()
        }
        // Fixtures honor the same store invariant as real imports.
        return ImageImportPipeline.process(image)
    }
}
#endif
