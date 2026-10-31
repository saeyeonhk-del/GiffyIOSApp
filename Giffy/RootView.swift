import SwiftUI

struct RootView: View {
    @State private var incoming = false
    @State private var validLink = false
    var body: some View {
        NavigationStack {
            ExploreView()
                // Register once on the stable navigation root. The previous destination
                // inside a conditional lazy grid disappeared when filters became empty.
                .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        }
        .onOpenURL { validLink = GiftRoute.code(from: $0) != nil; incoming = true }
        .sheet(isPresented: $incoming) {
            NavigationStack {
                ContentUnavailableView(validLink ? "Your gift" : "Invalid gift link", systemImage: "gift", description: Text(validLink ? "Secure gift lookup is not connected in this preview." : "Please check the link with the sender."))
                    .toolbar { Button("Done") { incoming = false } }
            }
        }
    }
}

struct ExploreView: View {
    @State private var showSignIn = false
    @State private var query = ""
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    HeroCarousel { reader.scrollTo("explore", anchor: .top) }
                        .padding(.horizontal, 16).padding(.top, 32).padding(.bottom, 48)
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Explore gifts by area").font(Brand.body(20, .bold))
                            Text("Find something they can enjoy nearby.").foregroundStyle(Brand.muted)
                        }
                        HStack(spacing: 8) {
                            ForEach(Area.all) { area in
                                NavigationLink { SearchView(area: area.name) } label: { AreaCard(area: area) }.buttonStyle(.plain)
                            }
                        }
                    }.padding(.horizontal, 20).padding(.vertical, 48).background(Brand.background).id("explore")
                    VStack(spacing: 16) {
                        Text("Find something they’ll love.").font(Brand.body(20, .bold))
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").foregroundStyle(Brand.muted)
                            TextField("Search for a gift, café, or treat...", text: $query).submitLabel(.search)
                            NavigationLink { SearchView(initialQuery: query) } label: { Image(systemName: "arrow.right").foregroundStyle(Brand.muted) }.accessibilityLabel("Search gifts")
                        }.padding(14).overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.border))
                    }.padding(.horizontal, 20).padding(.top, 24)
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Featured gifts").font(Brand.body(24, .bold))
                            Text("Hand-picked vouchers from top local vendors.").foregroundStyle(Brand.muted)
                            NavigationLink { SearchView() } label: { Text("View more products →").font(Brand.body(11, .medium)).foregroundStyle(Brand.muted) }.padding(.top, 4)
                        }
                        ProductGrid(products: Array(Catalog.products.prefix(6)))
                    }.padding(.horizontal, 20).padding(.vertical, 48)
                    HowItWorksView()
                    GiffyFooter().padding(.top, 64)
                    PreviewNotice().padding(20)
                }
            }.background(.white)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Image("logo").resizable().scaledToFit().frame(width: 82, height: 36).accessibilityLabel("Giffy") }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink { SearchView() } label: { Image(systemName: "magnifyingglass").foregroundStyle(Brand.muted) }.accessibilityLabel("Search")
                        Button("Sign in") { showSignIn = true }.font(Brand.body(12, .medium)).foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 9).background(Brand.ink, in: RoundedRectangle(cornerRadius: 8))
                        Menu {
                            NavigationLink("All Gifts") { SearchView() }
                            ForEach(Area.all) { area in NavigationLink(area.name) { SearchView(area: area.name) } }
                            NavigationLink("My Gifts") { MyGiftsView() }
                        } label: { Image(systemName: "line.3.horizontal").foregroundStyle(Brand.muted) }.accessibilityLabel("Menu")
                    }
                }
                .toolbarBackground(.white, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showSignIn) { SignInView() }
        }
    }
}

struct Area: Identifiable {
    let name: String
    let asset: String
    var id: String { name }
    static let all = [Area(name: "Central", asset: "central"), Area(name: "Wan Chai", asset: "wanchai"), Area(name: "Tsim Sha Tsui", asset: "tsimshatsui")]
}
struct AreaCard: View {
    let area: Area
    var body: some View {
        Color.clear.aspectRatio(0.8, contentMode: .fit)
            .overlay { Image(area.asset).resizable().scaledToFill() }
            .overlay { LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom) }
            .overlay(alignment: .bottomLeading) { HStack(spacing: 3) { Text(area.name).font(Brand.body(area.name.count > 10 ? 11 : 13, .semibold)).lineLimit(1).minimumScaleFactor(0.8); Spacer(minLength: 0); Image(systemName: "arrow.right").font(.system(size: 11)) }.foregroundStyle(.white).padding(10) }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProductGrid: View {
    let products: [Product]
    var body: some View {
        if products.isEmpty {
            ContentUnavailableView("No gifts found", systemImage: "magnifyingglass", description: Text("Try another category, area or search."))
        } else {
            // The mobile website uses three cards per row.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), alignment: .leading, spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(value: product) {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear.aspectRatio(1, contentMode: .fit).overlay { Image(product.asset).resizable().scaledToFill() }.clipped()
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 2) {
                                    Text(product.category).font(Brand.body(9, .medium)).foregroundStyle(badgeColor(product.category)).padding(.horizontal, 5).padding(.vertical, 3).background(badgeColor(product.category).opacity(0.08), in: Capsule())
                                    Spacer(minLength: 0)
                                    Text(product.priceLabel).font(Brand.body(11, .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                Text(product.name).font(Brand.body(11, .semibold)).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                            }.padding(8)
                            Spacer(minLength: 0)
                        }.frame(maxHeight: .infinity, alignment: .top).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xF3F4F6)))
                    }.buttonStyle(.plain).accessibilityLabel("\(product.name), \(product.vendor), \(product.priceLabel)")
                }
            }
        }
    }
}
func badgeColor(_ category: String) -> Color {
    switch category { case "Coffee": Color(hex: 0xB45309); case "Bakery": Color(hex: 0xC2410C); default: Color(hex: 0xBE185D) }
}

struct SearchView: View {
    @State private var query: String
    @State private var category = "All"
    let area: String?
    init(area: String? = nil, initialQuery: String = "", initialCategory: String = "All") { self.area = area; _query = State(initialValue: initialQuery); _category = State(initialValue: initialCategory) }
    var results: [Product] { Catalog.products.filter { (area == nil || $0.district == area) && (category == "All" || $0.category == category) && (query.isEmpty || "\($0.name) \($0.vendor) \($0.district ?? "")".localizedCaseInsensitiveContains(query)) } }
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) {
            Text(area ?? "All Gifts").font(Brand.body(28, .bold))
            Text("Find a little something they’ll love.").foregroundStyle(Brand.muted)
            CategoryPicker(selection: $category)
            ProductGrid(products: results)
            PreviewNotice()
        }.padding(20) }.background(.white).searchable(text: $query, prompt: "Search for a gift, café, or treat...").navigationBarTitleDisplayMode(.inline)
    }
}
struct CategoryPicker: View {
    @Binding var selection: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(["All", "Coffee", "Bakery", "Dessert"], id: \.self) { item in
            Button { selection = item } label: { Text(item).font(Brand.body(13, .medium)).padding(.horizontal, 16).padding(.vertical, 10).background(selection == item ? Brand.ink : Color(hex: 0xF3F4F6), in: Capsule()).foregroundStyle(selection == item ? Color.white : Brand.muted) }
        } } }
    }
}
struct HowItWorksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How Giffy works").font(Brand.body(24, .bold))
            Text("From “this made me think of you” to their phone in minutes.").foregroundStyle(Brand.muted).padding(.bottom, 20)
            ForEach(Array(zip(["Choose a gift", "Pay online", "Send the gift"], ["Find something they'll love.", "Quick and secure checkout.", "Share it through any messenger."]).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(String(format: "%02d", index + 1)).font(Brand.body(20, .semibold)).foregroundStyle(Brand.purple)
                    VStack(alignment: .leading, spacing: 4) { Text(step.0).font(Brand.body(16, .semibold)); Text(step.1).foregroundStyle(Brand.muted) }
                }.padding(.vertical, 16)
                if index < 2 { Divider() }
            }
        }.padding(.horizontal, 20).padding(.vertical, 48).frame(maxWidth: .infinity, alignment: .leading).background(Brand.background)
    }
}
struct GiffyFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image("logo").resizable().scaledToFit().frame(width: 82, height: 36)
            Text("Send a coffee, dessert, or bakery gift in seconds. The simplest way to make someone's day.").foregroundStyle(Brand.muted).lineSpacing(5)
            Divider().padding(.top, 16)
            Text("© 2026 Giffy. All rights reserved.").font(Brand.body(12)).foregroundStyle(Brand.muted)
            HStack(spacing: 24) { Link("Privacy", destination: URL(string: "https://giffy-copy-85814e59.base44.app/privacy")!); Link("Terms", destination: URL(string: "https://giffy-copy-85814e59.base44.app/terms")!) }.font(Brand.body(12)).foregroundStyle(Brand.muted)
        }.padding(.horizontal, 20).padding(.vertical, 48).frame(maxWidth: .infinity, alignment: .leading).background(Brand.background)
    }
}
struct MyGiftsView: View {
    @State private var signIn = false
    var body: some View {
        VStack(spacing: 24) {
            Text("My Gifts").font(Brand.body(28, .bold))
            Text("Please sign in to view your gifts.").foregroundStyle(Brand.muted)
            Button("Sign in") { signIn = true }.buttonStyle(GiffyButtonStyle())
            PreviewNotice()
        }.padding(24).sheet(isPresented: $signIn) { SignInView() }
    }
}
struct PreviewNotice: View {
    var body: some View { Text("Preview · catalogue snapshot · purchases unavailable").font(Brand.body(11)).foregroundStyle(Brand.muted).frame(maxWidth: .infinity, alignment: .leading) }
}
struct GiffyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(Brand.body(14, .semibold)).frame(maxWidth: .infinity, minHeight: 20).padding(.vertical, 16).background(configuration.isPressed ? Color(hex: 0x5A52E0) : Brand.purple, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
    }
}
