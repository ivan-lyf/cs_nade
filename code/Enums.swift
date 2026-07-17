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
