import Foundation

/// Live library filtering: selected chips combine as map ∧ side ∧ type, and
/// search matches title or either callout. Pure value logic so it's trivially
/// testable and the view stays thin.
struct LibraryFilter: Equatable {
    var map: GameMap?
    var side: Side?
    var type: NadeType?
    var search: String = ""

    var isActive: Bool {
        map != nil || side != nil || type != nil
            || !search.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func matches(_ item: Throw) -> Bool {
        if let map, item.map != map { return false }
        if let side, item.side != side { return false }
        if let type, item.type != type { return false }
        let query = search.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            let haystacks = [item.title, item.standCallout, item.targetCallout]
            guard haystacks.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            else { return false }
        }
        return true
    }
}
