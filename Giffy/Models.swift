import Foundation

struct Product: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let description: String
    let vendor: String
    let address: String
    let price: Double
    let category: String
    let district: String?
    let validityDays: Int
    let asset: String
    let detailAsset: String?
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, category, district, asset
        case vendor = "vendor_name", address = "vendor_address", validityDays = "validity_days", detailAsset = "detail_asset"
    }
    var priceLabel: String { "HK$" + price.formatted(.number.precision(.fractionLength(0...2))) }
}

enum Catalog {
    // Snapshot of publicly available products; never used to authorize a payment.
    static let products: [Product] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let products = try? JSONDecoder().decode([Product].self, from: data) else { return [] }
        return products
    }()
}
struct GiftDraft {
    var sender = ""
    var message = ""
    var valid: Bool { !sender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && sender.count <= 50 && message.count <= 200 }
}
enum GiftRoute {
    static let host = "giffy-copy-85814e59.base44.app"
    static func code(from url: URL) -> String? {
        guard url.scheme == "https", url.host == host, url.path == "/gift",
              let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value,
              !code.isEmpty, code.count <= 64,
              code.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-").contains($0) }) else { return nil }
        return code
    }
}
