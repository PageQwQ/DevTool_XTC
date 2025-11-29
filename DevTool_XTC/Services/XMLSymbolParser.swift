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
}
