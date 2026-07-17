import Foundation

// String-backed so SwiftData stores the raw value, keeps CloudKit happy,
// and predicates can filter on it directly.

enum GameMap: String, Codable, CaseIterable, Identifiable {
    case dust2, mirage, inferno, nuke, overpass, ancient, anubis, train, vertigo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dust2:    "Dust II"
        case .mirage:   "Mirage"
        case .inferno:  "Inferno"
        case .nuke:     "Nuke"
        case .overpass: "Overpass"
        case .ancient:  "Ancient"
        case .anubis:   "Anubis"
        case .train:    "Train"
        case .vertigo:  "Vertigo"
        }
    }

    /// Compact code for map-picker cells and meta tags (design/README §4).
    var code: String {
        switch self {
        case .dust2:    "D2"
        case .mirage:   "MIR"
        case .inferno:  "INF"
        case .nuke:     "NUKE"
        case .overpass: "OVP"
        case .ancient:  "ANC"
        case .anubis:   "ANB"
        case .train:    "TRN"
        case .vertigo:  "VRT"
        }
    }

    /// Active-Duty pool (Premier / Majors), July 2026 per CS2_TERMS §3. Lets the
    /// picker highlight the seven currently-competitive maps and dim the reserves.
    var isActiveDuty: Bool {
        switch self {
        case .ancient, .anubis, .dust2, .inferno, .mirage, .nuke, .overpass: true
        case .train, .vertigo: false
        }
    }
}

enum Side: String, Codable, CaseIterable, Identifiable {
    case t = "T"
    case ct = "CT"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum NadeType: String, Codable, CaseIterable, Identifiable {
    case smoke, flash, molly, he, decoy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .smoke: "Smoke"
        case .flash: "Flash"
        case .molly: "Molotov"
        case .he:    "HE"
        case .decoy: "Decoy"
        }
    }
}

enum ImageRole: String, Codable, CaseIterable, Identifiable {
    case stand, aim, landing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stand:   "Stand"
        case .aim:     "Aim"
        case .landing: "Landing"
        }
    }
}

// MARK: - Throw technique (CS2_TERMS §1, §5)

/// How hard the nade is thrown (mouse input). Almost any power combines with
/// almost any movement, so power and movement are modeled as separate fields.
enum ThrowPower: String, Codable, CaseIterable, Identifiable {
    case left, right, both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .left:  "Left-click"
        case .right: "Right-click"
        case .both:  "Both"
        }
    }

    /// Short code for technique tags, e.g. the "L" in "JUMP·L".
    var code: String {
        switch self {
        case .left:  "L"
        case .right: "R"
        case .both:  "L+R"
        }
    }
}

/// How the player moves while throwing.
enum ThrowMovement: String, Codable, CaseIterable, Identifiable {
    case standing, walk, run, jump, runJump, crouch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standing: "Standing"
        case .walk:     "Walk-throw"
        case .run:      "Run-throw"
        case .jump:     "Jump-throw"
        case .runJump:  "Run-jump-throw"
        case .crouch:   "Crouch-throw"
        }
    }

    /// Short code for technique tags, e.g. the "JUMP" in "JUMP·L".
    var code: String {
        switch self {
        case .standing: "STAND"
        case .walk:     "WALK"
        case .run:      "RUN"
        case .jump:     "JUMP"
        case .runJump:  "RUNJUMP"
        case .crouch:   "CROUCH"
        }
    }
}
