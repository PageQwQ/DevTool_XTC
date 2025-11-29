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
    @Published var stats: [String: Int] = [:]

    private let parser = XMLSymbolParser()
    private var repeatTimer: Timer?
    private var repeatingItem: SymbolItem?

    func importXML(url: URL) {
        var didAccess = false
        if url.startAccessingSecurityScopedResource() { didAccess = true }
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let cats = try parser.parse(url: url)
            categories = cats
            importedURL = url
            parseError = nil
            saveBookmark(url)
        } catch {
            categories = []
            parseError = error.localizedDescription
        }
    }

    func insert(_ item: SymbolItem) {
        if item.text.isEmpty { return }
        if pairModeEnabled, let l = item.left, let r = item.right {
            text.append(l)
            text.append(r)
        } else {
            text.append(item.text)
        }
        let k = item.key ?? item.text
        if !k.isEmpty {
            stats[k, default: 0] += 1
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
