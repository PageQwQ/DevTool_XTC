import Foundation

struct SymbolItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let left: String?
    let right: String?
    let hint: String?
    let repeatable: Bool
    let key: String?
}

struct SymbolCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let comment: String?
    let column: Int
    let locked: Bool
    let symbols: [SymbolItem]
}
