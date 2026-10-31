import SwiftUI

struct ProductDetailView: View {
    let product: Product
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ProductArtwork(product: product).frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 26))
                HStack { Text(product.category.uppercased()).font(.caption.bold()).tracking(2).foregroundStyle(Brand.purple); Spacer(); Text(product.priceLabel).font(.title2.bold()) }
                Text(product.name).font(.system(size: 34, weight: .medium, design: .serif))
                Label(product.vendor, systemImage: "storefront")
                Label(product.district + ", Hong Kong", systemImage: "mappin.and.ellipse").foregroundStyle(.secondary)
                Divider()
                Text("A gift for their everyday.").font(.title3.bold())
                Text(product.description).foregroundStyle(.secondary)
                Text("Good to know").font(.headline)
                Text("Single voucher for the selected experience. Final inclusions, redemption conditions and expiry will be shown from the live catalogue before payment.").foregroundStyle(.secondary)
                PreviewNotice()
            }.padding(20)
        }
        .navigationTitle("A little something").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            NavigationLink { GiftMessageView(product: product) } label: { Text("Make it personal · \(product.priceLabel)") }.buttonStyle(GiffyButtonStyle()).padding().background(.regularMaterial)
        }
    }
}

struct GiftMessageView: View {
    let product: Product
    @State private var draft = GiftDraft()
    @State private var showSignIn = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Make it theirs.").font(.system(size: 38, weight: .medium, design: .serif))
                Text("A few words can make a small gift mean so much.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 14) {
                    Text("From").font(.headline)
                    TextField("Your name", text: $draft.sender).textContentType(.name).padding().background(Brand.cream, in: RoundedRectangle(cornerRadius: 14))
                    Text("Required · \(draft.sender.count)/50 characters").font(.caption).foregroundStyle(draft.sender.count > 50 ? .red : .secondary)
                    Text("Your message").font(.headline)
                    TextField("Saw this and thought of you…", text: $draft.message, axis: .vertical).lineLimit(4...8).padding().background(Brand.cream, in: RoundedRectangle(cornerRadius: 14))
                    Text("Optional · \(draft.message.count)/200 characters").font(.caption).foregroundStyle(draft.message.count > 200 ? .red : .secondary)
                }
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "gift.fill").foregroundStyle(Brand.purple)
                    Text(product.name).font(.title3.weight(.medium)).fontDesign(.serif)
                    Text(draft.message.isEmpty ? "Your little note goes here." : draft.message).foregroundStyle(.secondary)
                    Text("From \(draft.sender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "you" : draft.sender)").font(.subheadline.bold())
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Brand.cream, in: RoundedRectangle(cornerRadius: 22))
                HStack { Text("Gift price"); Spacer(); Text(product.priceLabel).bold() }
                Text("Final payment total will be confirmed by the server before checkout.").font(.caption).foregroundStyle(.secondary)
                PreviewNotice()
            }.padding(20)
        }
        .navigationTitle("Your gift").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Sign in to continue") { showSignIn = true }.buttonStyle(GiffyButtonStyle()).disabled(!draft.valid).opacity(draft.valid ? 1 : 0.45).padding().background(.regularMaterial)
        }
        .sheet(isPresented: $showSignIn) { SignInView() }
    }
}

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showExplanation = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "gift.fill").font(.system(size: 48)).foregroundStyle(Brand.purple)
                Text("A little joy starts here.").font(.system(size: 32, weight: .medium, design: .serif)).multilineTextAlignment(.center)
                Text("Sign in to keep your gifts together.").foregroundStyle(.secondary)
                Button { showExplanation = true } label: { Label("Continue with Apple", systemImage: "apple.logo").frame(maxWidth: .infinity).padding(18).background(.black, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(.white) }
                Button { showExplanation = true } label: { Text("Continue with Google").font(.headline).frame(maxWidth: .infinity).padding(18).background(Brand.cream, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(.primary) }
                Text("Preview: authentication is not connected yet.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                HStack { Link("Privacy", destination: URL(string: "https://giffy-copy-85814e59.base44.app/privacy")!); Text("·"); Link("Terms", destination: URL(string: "https://giffy-copy-85814e59.base44.app/terms")!) }.font(.caption)
            }.padding(28)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .alert("Sign-in is being prepared", isPresented: $showExplanation) { Button("OK", role: .cancel) {} } message: { Text("Apple and Google sign-in require provider configuration and a verified account connection to Giffy. This preview does not create an account or charge you.") }
        }
    }
}
