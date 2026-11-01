import SwiftUI
import CoreText

@main
struct GiffyApp: App {
    @StateObject private var auth = AuthStore()
    init() {
        for name in ["inter", "fraunces"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(auth).task { await auth.restore() }.font(Brand.body(14)).foregroundStyle(Brand.ink)
                .tint(Brand.purple).preferredColorScheme(.light)
        }
    }
}

enum Brand {
    static let purple = Color(hex: 0x6C63FF)
    static let orange = Color(hex: 0xD96A46)
    static let ink = Color(hex: 0x111111)
    static let muted = Color(hex: 0x6B7280)
    static let border = Color(hex: 0xE5E7EB)
    static let background = Color(hex: 0xF9F9F9)
    static let cream = background
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Inter-Regular", size: size, relativeTo: .body).weight(weight)
    }
    static func serif(_ size: CGFloat) -> Font {
        .custom("GiffyFraunces-Regular", size: size, relativeTo: .title)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255)
    }
}
