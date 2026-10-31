import Foundation

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let vendor: String
    let price: Int
    let category: String
    let district: String
    let symbol: String
    let description: String
    var priceLabel: String { "HK$\(price)" }
}

enum Catalog {
    // Preview fixtures based on the public Giffy storefront; not live inventory.
    static let products: [Product] = [
        Product(id: "6a956c4f9ef5b8843696b5b0", name: "Single Origin Pour-Over Voucher", vendor: "I love tea", price: 85, category: "Coffee", district: "Central", symbol: "cup.and.saucer.fill", description: "A little pause in their day. Discover a thoughtfully brewed single origin coffee from a local favourite."),
        Product(id: "6a956c4f9ef5b8843696b5b5", name: "Cinnamon Brioche Knot Box", vendor: "Cafe Hachu", price: 95, category: "Bakery", district: "Wan Chai", symbol: "birthday.cake.fill", description: "Something sweet for someone special. A comforting bakery treat, ready to brighten their afternoon."),
        Product(id: "6a956c4f9ef5b8843696b5b2", name: "Cold Brew Tasting Flight", vendor: "donut heaven", price: 120, category: "Coffee", district: "Tsim Sha Tsui", symbol: "mug.fill", description: "Send a refreshing discovery. A tasting experience for the coffee lover in your life.")
    ]
}

struct GiftDraft {
    var sender = ""
    var message = ""
    var valid: Bool { !sender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && sender.count <= 50 && message.count <= 200 }
}

// Deliberately separate the app's owner-only gifts from recipient link access.
enum GiftRoute {
    static let host = "giffy-copy-85814e59.base44.app"
    static func code(from url: URL) -> String? {
        guard url.scheme == "https", url.host == host, url.path == "/gift",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let code = items.first(where: { $0.name == "code" })?.value,
              !code.isEmpty, code.count <= 64,
              code.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-").contains($0) }) else { return nil }
        return code
    }
}
