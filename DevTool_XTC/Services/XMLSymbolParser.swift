import Foundation

final class XMLSymbolParser: NSObject, XMLParserDelegate {
    private var categories: [SymbolCategory] = []
    private var currentAttrs: [String: String] = [:]
    private var currentSymbols: [SymbolItem] = []

    func parse(url: URL) throws -> [SymbolCategory] {
        categories = []
        currentAttrs = [:]
        currentSymbols = []
        let data = try Data(contentsOf: url)
        let parser = XMLParser(data: data)
        parser.delegate = self
        let ok = parser.parse()
        if !ok {
            throw parser.parserError ?? NSError(domain: "XMLSymbolParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "XML 解析失败"])
        }
        if categories.isEmpty {
            throw NSError(domain: "XMLSymbolParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "未解析到任何分栏（检查 <Symbols>/<Category> 结构）"])
        }
        return categories
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Category" {
            currentAttrs = attributeDict
            currentSymbols = []
        } else if elementName == "Symbol" {
            let text = attributeDict["text"] ?? ""
            let left = attributeDict["left"]
            let right = attributeDict["right"]
            let hint = attributeDict["hint"]
            let repeatable = (attributeDict["repeatable"] ?? "false").lowercased() == "true"
            let key = attributeDict["key"]
            let item = SymbolItem(text: text, left: left, right: right, hint: hint, repeatable: repeatable, key: key)
            currentSymbols.append(item)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Category" {
            let name = currentAttrs["name"] ?? ""
            let comment = currentAttrs["comment"]
            let column = Int(currentAttrs["column"] ?? "4") ?? 4
            let locked = (currentAttrs["lock"] ?? "false").lowercased() == "true"
            let category = SymbolCategory(name: name, comment: comment, column: max(1, min(8, column)), locked: locked, symbols: currentSymbols)
            categories.append(category)
            currentAttrs = [:]
            currentSymbols = []
        }
    }

    static func serialize(_ categories: [SymbolCategory]) -> String {
        var out: [String] = []
        out.append("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
        out.append("<Symbols>")
        for cat in categories {
            var attrs: [String] = []
            attrs.append("class=\"1\"")
            attrs.append("column=\"\(cat.column)\"")
            if let c = cat.comment { attrs.append("comment=\"\(escape(c))\"") }
            attrs.append("lock=\"\(cat.locked ? "true" : "false")\"")
            attrs.append("name=\"\(escape(cat.name))\"")
            out.append("    <Category \(attrs.joined(separator: " "))>")
            for s in cat.symbols {
                var sAttrs: [String] = []
                sAttrs.append("text=\"\(escape(s.text))\"")
                if let l = s.left { sAttrs.append("left=\"\(escape(l))\"") }
                if let r = s.right { sAttrs.append("right=\"\(escape(r))\"") }
                if let h = s.hint { sAttrs.append("hint=\"\(escape(h))\"") }
                if s.repeatable { sAttrs.append("repeatable=\"true\"") }
                if let k = s.key { sAttrs.append("key=\"\(escape(k))\"") }
                out.append("        <Symbol \(sAttrs.joined(separator: " ")) />")
            }
            out.append("    </Category>")
        }
        out.append("</Symbols>")
        return out.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: "&", with: "&amp;")
        r = r.replacingOccurrences(of: "\"", with: "&quot;")
        r = r.replacingOccurrences(of: "<", with: "&lt;")
        r = r.replacingOccurrences(of: ">", with: "&gt;")
        return r
    }
}
