import SwiftUI

@main
struct GiffyApp: App {
    var body: some Scene {
        WindowGroup { RootView().tint(Brand.purple).preferredColorScheme(.light) }
    }
}

enum Brand {
    static let purple = Color(red: 108/255, green: 99/255, blue: 1)
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.95)
}
