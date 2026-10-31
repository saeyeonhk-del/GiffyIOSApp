import Foundation

@main
struct ModelChecks {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let products = try JSONDecoder().decode([Product].self, from: Data(contentsOf: root.appendingPathComponent("Giffy/catalog.json")))
        precondition(products.count == 3 && Set(products.map(\.id)).count == 3)
        for product in products {
            precondition(product.price > 0 && !product.vendor.isEmpty)
            precondition(FileManager.default.fileExists(atPath: root.appendingPathComponent("Giffy/Assets.xcassets/\(product.asset).imageset/Contents.json").path))
        }
        precondition(GiftRoute.code(from: URL(string: "https://giffy-copy-85814e59.base44.app/gift?code=GFT-123")!) == "GFT-123")
        for invalid in ["https://evil.example/gift?code=GFT-123", "http://giffy-copy-85814e59.base44.app/gift?code=GFT-123", "https://giffy-copy-85814e59.base44.app/gift?code=", "https://giffy-copy-85814e59.base44.app/gift?code=%3Cscript%3E"] {
            precondition(GiftRoute.code(from: URL(string: invalid)!) == nil)
        }
        var draft = GiftDraft()
        draft.sender = "   \n"; precondition(!draft.valid)
        draft.sender = "해니 🎁"; draft.message = String(repeating: "🎉", count: 200); precondition(draft.valid)
        draft.message += "🎉"; precondition(!draft.valid)
        draft.message = ""; draft.sender = String(repeating: "a", count: 51); precondition(!draft.valid)
        print("PASS: public catalogue, bundled images, gift-link validation and Unicode message limits")
    }
}
