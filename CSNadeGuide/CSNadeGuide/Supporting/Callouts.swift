import Foundation

/// Per-map callout names, from CS2_TERMS §4. These feed the stand/target callout
/// autocomplete on the create/edit form so entries stay consistent (and become
/// filterable later). Primary names only — regional variants are collapsed to
/// one. Covers the seven active-duty maps; Train and Vertigo are intentionally
/// empty until lineups are seeded for them.
enum Callouts {
    static let byMap: [GameMap: [String]] = [
        .dust2: [
            "Long A", "Long Doors", "Blue", "Pit", "Side Pit", "Car", "Goose",
            "A Ramp", "Barrels", "A Plat", "A Default", "Ninja", "A Short",
            "Stairs", "Catwalk", "Mid", "Mid Doors", "Xbox", "CT Mid", "Top Mid",
            "Palm", "Green", "Suicide", "B Doors", "B Plat", "Back Plat", "B Car",
            "Closet", "Fence", "Window", "B Default", "Big Box", "Double Stack",
            "B Back Site", "Dog", "Upper Tunnels", "Lower Tunnels",
            "Outside Tunnels", "T Spawn", "T Plat", "Titanic", "Outside Long",
            "CT Spawn",
        ],
        .mirage: [
            "T Ramp", "Palace", "Tetris", "Firebox", "Triple", "A Default",
            "Ninja", "Stairs", "Jungle", "Ticket", "Sandwich", "Pillars",
            "A Balcony", "CT", "Top Mid", "Mid", "Mid Boxes", "Window",
            "Connector", "Catwalk", "Chair", "Underpass", "Ladder Room",
            "Short Boost", "B Apartments", "Balcony", "House", "Market",
            "Kitchen", "Bench", "Van", "B Default", "B Short", "Back Alley",
            "B Site", "T Spawn", "CT Spawn",
        ],
        .inferno: [
            "Apartments", "Balcony", "Pit", "Graveyard", "Truck", "A Short",
            "A Long", "Arch", "Arch Side", "Library", "Kitchen", "Moto", "Patio",
            "A Default", "Close Left", "Back Site", "Mid", "Top Mid",
            "Bottom Mid", "Second Mid", "Underpass", "Boiler", "Bridge",
            "T Apps", "Bench", "Banana", "Logs", "Car", "Sandbags", "Coffins",
            "Dark", "Fountain", "Construction", "Garden", "New Box", "CT",
            "Boost", "B Site", "T Spawn", "T Ramp", "CT Spawn", "Speedway",
            "Terrace", "Well",
        ],
        .nuke: [
            "Heaven", "Hell", "Rafters", "Mustang", "Hut", "Squeaky", "Tetris",
            "Sandbags", "Mini", "A Main", "Radio", "Crane", "Vents", "Ramp",
            "Ramp Room", "Control", "Lockers", "New Box", "Dark", "Secret",
            "Double", "Decon", "Window", "Blue Box", "Back Vents", "Turn Pike",
            "Headshot", "Big Box", "Boost", "Bottom Ramp", "Silo", "Toxic",
            "Garage", "Trophy", "Warehouse", "T Red", "CT Red", "Main Drop",
            "Lobby", "CT Roof", "T Spawn", "CT Spawn",
        ],
        .ancient: [
            "A Main", "A Halls", "A Stairs", "A Ramp", "Boost", "Big Box",
            "Plat", "Single", "Triple", "A Default", "Temple", "Lane", "Cubby",
            "Short", "Mid", "Top Mid", "Bottom Mid", "Xbox", "Pit",
            "Snipers Nest", "Elbow", "Split", "Donut", "Cave", "Heaven",
            "Mid Cubby", "B Site", "B Main", "Lamp Room", "Pillar", "House",
            "Back Halls", "Square", "Nest", "Alley", "B Ramp", "Catwalk",
            "Cheetah", "T Lower", "Water", "Altar", "T Spawn", "T House",
            "CT Spawn",
        ],
        .anubis: [
            "A Main", "A Long", "Temple", "A Site", "Heaven", "Fountain",
            "A Connector", "Plateau", "A Backsite", "Palace", "Walkway",
            "Middle", "Top Mid", "Bridge", "Double Doors", "Connector", "Canal",
            "Ruins", "Alley", "B Main", "B Site", "B Long", "B Connector",
            "Pillar", "Gate", "Ninja", "Back Site", "Coffins", "Window",
            "Street", "Water", "Boat", "Arches", "Wood", "Beach", "Stairs",
            "Upper", "Drop", "T Spawn", "CT Spawn",
        ],
        .overpass: [
            "A Main", "A Site", "Truck", "Van", "Bank", "Bins", "Close Left",
            "A Default", "A Long", "Long Toilets", "Cafe", "Bench", "Rock",
            "Tree", "Signpost", "Hitmarker", "Storage", "Mid", "Top Mid",
            "Toilets", "Fountain", "Playground", "Balloons", "Party",
            "Connector", "Water", "Monster", "Sewers", "B Site", "Pillar",
            "Barrels", "Heaven", "Pit", "Walkway", "Bridge", "ABC", "B Short",
            "Sandbags", "Tracks", "Short Tunnel", "Squeaky", "Upper Tunnels",
            "Lower Tunnels", "Ladder", "Dropout", "T Spawn", "CT Spawn",
        ],
        .train: [],
        .vertigo: [],
    ]

    /// Callouts for a map, or an empty list if none are catalogued yet.
    static func list(for map: GameMap) -> [String] {
        byMap[map] ?? []
    }
}
