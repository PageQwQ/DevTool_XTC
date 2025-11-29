import Foundation

final class XMLSymbolParser: NSObject, XMLParserDelegate {
    private var categories: [SymbolCategory] = []
    private var currentAttrs: [String: String] = [:]
    private var currentSymbols: [SymbolItem] = []

    func parse(url: URL) throws -> [SymbolCategory] {
        let data = try Data(contentsOf: url)
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
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
