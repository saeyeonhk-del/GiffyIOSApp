import SwiftUI

struct RootView: View {
    @State private var incomingGift: String?
    @State private var showIncoming = false
    var body: some View {
        TabView {
            NavigationStack { ExploreView() }
                .tabItem { Label("Explore", systemImage: "sparkles") }
            NavigationStack { SearchView() }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { MyGiftsView() }
                .tabItem { Label("My Gifts", systemImage: "gift") }
        }
        .onOpenURL { url in
            incomingGift = GiftRoute.code(from: url)
            showIncoming = true
        }
        .sheet(isPresented: $showIncoming) {
            NavigationStack {
                ContentUnavailableView(incomingGift == nil ? "Invalid gift link" : "Your gift", systemImage: "gift", description: Text(incomingGift == nil ? "Please check the link with the sender." : "Gift lookup will be available after the secure server connection is configured. No voucher status has been verified."))
                    .toolbar { Button("Done") { showIncoming = false } }
            }
        }
    }
}

struct ExploreView: View {
    @State private var category = "All"
    @State private var district = "All areas"
    private var products: [Product] {
        Catalog.products.filter { (category == "All" || $0.category == category) && (district == "All areas" || $0.district == district) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack { Text("Giffy").font(.system(size: 32, weight: .bold, design: .rounded)); Spacer(); Image(systemName: "gift.fill").foregroundStyle(Brand.purple) }
                VStack(alignment: .leading, spacing: 18) {
                    Text("A SMALL, THOUGHTFUL GIFT").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Brand.purple)
                    Text("Send a little\nsomething.").font(.system(size: 45, weight: .medium, design: .serif)).minimumScaleFactor(0.7)
                    Text("Coffee, cake and good things from places they’ll love.").foregroundStyle(.secondary)
                    NavigationLink(destination: SearchView()) { Label("Find a gift", systemImage: "arrow.right").font(.subheadline.bold()).padding().background(Brand.purple, in: Capsule()).foregroundStyle(.white) }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Brand.cream, in: RoundedRectangle(cornerRadius: 26))
                HStack { Text("A little closer to them").font(.title3.bold()); Spacer() }
                Picker("Area", selection: $district) { ForEach(["All areas", "Central", "Wan Chai", "Tsim Sha Tsui"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                CategoryPicker(selection: $category)
                HStack { Text("Featured gifts").font(.title2.bold()); Spacer(); Text("\(products.count) gifts").font(.caption).foregroundStyle(.secondary) }
                ProductGrid(products: products)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Small gesture. Big smile.").font(.title2.weight(.medium)).fontDesign(.serif)
                    Text("01  Choose a gift\n02  Make it personal\n03  Send a little joy").lineSpacing(12).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Brand.cream, in: RoundedRectangle(cornerRadius: 24))
                PreviewNotice()
            }.padding(20)
        }.toolbar(.hidden, for: .navigationBar)
    }
}

struct CategoryPicker: View {
    @Binding var selection: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack { ForEach(["All", "Coffee", "Bakery", "Dessert"], id: \.self) { item in
                Button { selection = item } label: { Text(item).font(.subheadline.weight(.medium)).padding(.horizontal, 18).padding(.vertical, 12).background(selection == item ? Brand.purple : Color.gray.opacity(0.08), in: Capsule()).foregroundStyle(selection == item ? Color.white : Color.primary) }
                    .accessibilityAddTraits(selection == item ? .isSelected : [])
            } }
        }
    }
}

struct ProductGrid: View {
    let products: [Product]
    var body: some View {
        if products.isEmpty {
            ContentUnavailableView("No gifts found", systemImage: "magnifyingglass", description: Text("Try another category, area or search."))
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 20) {
                ForEach(products) { product in
                    NavigationLink(value: product) {
                        VStack(alignment: .leading, spacing: 10) {
                            ProductArtwork(product: product).frame(height: 155).clipped()
                            VStack(alignment: .leading, spacing: 7) {
                                HStack { Text(product.category).font(.caption2).foregroundStyle(Brand.purple); Spacer(); Text(product.priceLabel).font(.caption.bold()) }
                                Text(product.name).font(.subheadline.weight(.semibold)).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                                Text(product.vendor).font(.caption).foregroundStyle(.secondary)
                            }.padding([.horizontal, .bottom], 12)
                        }.background(.white, in: RoundedRectangle(cornerRadius: 20)).clipShape(RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.gray.opacity(0.15)))
                    }.buttonStyle(.plain)
                }
            }.navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        }
    }
}

struct ProductArtwork: View {
    let product: Product
    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.cream, Brand.purple.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.55)).frame(width: 118, height: 118)
            Image(systemName: product.symbol).font(.system(size: 54, weight: .light)).foregroundStyle(Brand.purple)
        }.accessibilityHidden(true)
    }
}

struct SearchView: View {
    @State private var query = ""
    @State private var category = "All"
    var results: [Product] { Catalog.products.filter { (category == "All" || $0.category == category) && (query.isEmpty || "\($0.name) \($0.vendor) \($0.district)".localizedCaseInsensitiveContains(query)) } }
    var body: some View {
        ScrollView { VStack(spacing: 24) { CategoryPicker(selection: $category); ProductGrid(products: results); PreviewNotice() }.padding(20) }
            .navigationTitle("Find their little joy")
            .searchable(text: $query, prompt: "Coffee, bakery, places…")
    }
}

struct MyGiftsView: View {
    @State private var showSignIn = false
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "gift").font(.system(size: 62, weight: .ultraLight)).foregroundStyle(Brand.purple)
            Text("All your little gestures.").font(.system(size: 30, weight: .medium, design: .serif)).multilineTextAlignment(.center)
            Text("Sign in to find your gifts and see when they’ve made someone’s day.").foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Sign in") { showSignIn = true }.buttonStyle(GiffyButtonStyle())
            Spacer()
            PreviewNotice()
        }.padding(28).navigationTitle("My Gifts").sheet(isPresented: $showSignIn) { SignInView() }
    }
}

struct PreviewNotice: View {
    var body: some View { Label("Preview · sample catalogue · purchases unavailable", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
}

struct GiffyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(18).background(Brand.purple.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(.white)
    }
}
