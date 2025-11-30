import Foundation
import SwiftUI
import Combine

final class KeyboardViewModel: ObservableObject {
    @Published var categories: [SymbolCategory] = []
    @Published var currentIndex: Int = 0
    @Published var importedURL: URL?
    @Published var text: String = ""
    @Published var showImporter: Bool = false
    @Published var parseError: String?
    @Published var pairModeEnabled: Bool = true
    @Published var repeatEnabled: Bool = true
    @Published var xmlSource: String = ""
    @Published var isDirty: Bool = false

    private let parser = XMLSymbolParser()
    private var repeatTimer: Timer?
    private var repeatingItem: SymbolItem?

    func importXML(url: URL) {
        var didAccess = false
        if url.startAccessingSecurityScopedResource() { didAccess = true }
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            xmlSource = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
            let cats = try parser.parse(url: url)
            categories = cats
            importedURL = url
            parseError = nil
            saveBookmark(url)
            isDirty = false
        } catch {
            categories = []
            parseError = error.localizedDescription
        }
    }

    func insert(_ item: SymbolItem) {
        var display = item.text
        if display.hasPrefix("\\") { display.removeFirst() }
        if display.isEmpty { return }
        if pairModeEnabled, let l = item.left, let r = item.right {
            text.append(l)
            text.append(r)
        } else {
            text.append(display)
        }
        
    }

    func backspace() {
        guard !text.isEmpty else { return }
        _ = text.popLast()
    }

    func startRepeating(item: SymbolItem) {
        guard repeatEnabled else { return }
        repeatingItem = item
        repeatTimer?.invalidate()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self, let it = self.repeatingItem else { return }
            self.insert(it)
        }
    }

    func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatingItem = nil
    }

    func addSymbol(text: String) {
        guard !text.isEmpty else { return }
        guard categories.indices.contains(currentIndex) else { return }
        let cat = categories[currentIndex]
        var syms = cat.symbols
        let newItem = SymbolItem(text: text, left: nil, right: nil, hint: nil, repeatable: false, key: nil)
        let insertPos = (syms.lastIndex(where: { !$0.text.isEmpty }) ?? max(0, syms.count - 1)) + 1
        syms.insert(newItem, at: min(insertPos, syms.count))
        categories[currentIndex] = SymbolCategory(name: cat.name, comment: cat.comment, column: cat.column, locked: cat.locked, symbols: syms)
        ensurePlaceholdersForCurrentCategory()
        regenerateXML()
        isDirty = true
    }

    func regenerateXML() {
        xmlSource = XMLSymbolParser.serialize(categories)
    }

    func saveXML() {
        guard let url = importedURL else { return }
        var didAccess = false
        if url.startAccessingSecurityScopedResource() { didAccess = true }
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            regenerateXML()
            let data = xmlSource.data(using: .utf8) ?? Data()
            try data.write(to: url, options: .atomic)
            isDirty = false
            parseError = nil
        } catch {
            parseError = "保存失败: \(error.localizedDescription)"
        }
    }

    func saveXML(to url: URL) {
        var didAccess = false
        if url.startAccessingSecurityScopedResource() { didAccess = true }
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            regenerateXML()
            let data = xmlSource.data(using: .utf8) ?? Data()
            try data.write(to: url, options: .atomic)
            importedURL = url
            saveBookmark(url)
            isDirty = false
            parseError = nil
        } catch {
            parseError = "保存失败: \(error.localizedDescription)"
        }
    }

    private func ensurePlaceholdersForCurrentCategory() {
        guard categories.indices.contains(currentIndex) else { return }
        let cat = categories[currentIndex]
        let header = cat.symbols.first ?? SymbolItem(text: "", left: nil, right: nil, hint: nil, repeatable: false, key: nil)
        let gridItems = Array(cat.symbols.dropFirst())
        let nonEmpty = gridItems.filter { !$0.text.isEmpty }
        let col = max(1, cat.column)
        let remainder = nonEmpty.count % col
        let need = remainder == 0 ? 0 : (col - remainder)
        var newSyms: [SymbolItem] = [header]
        newSyms.append(contentsOf: nonEmpty)
        if need > 0 {
            newSyms.append(contentsOf: Array(repeating: SymbolItem(text: "", left: nil, right: nil, hint: nil, repeatable: false, key: nil), count: need))
        }
        categories[currentIndex] = SymbolCategory(name: cat.name, comment: cat.comment, column: cat.column, locked: cat.locked, symbols: newSyms)
    }

    func updateSymbol(id: UUID, text: String) {
        guard categories.indices.contains(currentIndex) else { return }
        let cat = categories[currentIndex]
        var syms = cat.symbols
        if let idx = syms.firstIndex(where: { $0.id == id }) {
            let old = syms[idx]
            syms[idx] = SymbolItem(text: text, left: old.left, right: old.right, hint: old.hint, repeatable: old.repeatable, key: old.key)
            categories[currentIndex] = SymbolCategory(name: cat.name, comment: cat.comment, column: cat.column, locked: cat.locked, symbols: syms)
            ensurePlaceholdersForCurrentCategory()
            regenerateXML()
            isDirty = true
        }
    }


    func loadLastBookmarkIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: "lastXMLBookmark") else { return }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
            _ = url.startAccessingSecurityScopedResource()
            importXML(url: url)
        }
    }

    private func saveBookmark(_ url: URL) {
        if let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: "lastXMLBookmark")
        }
    }
}
