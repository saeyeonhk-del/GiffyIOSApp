import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var checkoutNotice = false
    let product: Product
    @State private var draft = GiftDraft()
    @State private var signIn = false
    @State private var senderError = false
    @FocusState private var focused: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(product.category + " Voucher").font(Brand.body(12, .semibold)).foregroundStyle(badgeColor(product.category)).padding(.horizontal, 12).padding(.vertical, 6).background(badgeColor(product.category).opacity(0.08), in: Capsule())
                Text(product.name).font(Brand.body(24, .bold))
                HStack(alignment: .firstTextBaseline, spacing: 4) { Text(product.priceLabel).font(Brand.body(20, .bold)); Text("/ voucher").font(Brand.body(17)).foregroundStyle(Brand.muted.opacity(0.8)) }.foregroundStyle(Brand.muted)
                Label("Valid for \(product.validityDays) days from purchase", systemImage: "calendar.badge.clock").font(Brand.body(12)).foregroundStyle(Brand.muted)
                Color.clear.aspectRatio(4/3, contentMode: .fit).overlay { Image(product.asset).resizable().scaledToFill() }.clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) { Image(systemName: "storefront").padding(8).background(.white, in: RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading, spacing: 3) { Text("VENDOR").font(Brand.body(12, .medium)).foregroundStyle(Brand.muted); Text(product.vendor).font(Brand.body(14, .semibold)) } }
                    Label(product.address, systemImage: "mappin.and.ellipse").font(Brand.body(12)).foregroundStyle(Brand.muted)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: 0xF9FAFB), in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xF3F4F6)))
                Divider().padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 8) {
                    Text("From").font(Brand.body(14, .medium))
                    TextField("Your name", text: $draft.sender).textContentType(.name).focused($focused).padding(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(senderError ? Color.red : Brand.border))
                        .onChange(of: draft.sender) { _, value in draft.sender = String(value.prefix(50)); if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { senderError = false } }
                    if senderError { Text("Please enter your name.").font(Brand.body(12)).foregroundStyle(.red) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a personal message (optional)").font(Brand.body(14, .medium))
                    TextField("Happy Birthday! Hope you enjoy this gift.", text: $draft.message, axis: .vertical).lineLimit(3...5).focused($focused).padding(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.border))
                        .onChange(of: draft.message) { _, value in draft.message = String(value.prefix(200)) }
                    Text("\(draft.message.count)/200").font(Brand.body(12)).foregroundStyle(Brand.muted).frame(maxWidth: .infinity, alignment: .trailing)
                }
                Button(auth.user == nil ? "Sign in to purchase" : "Purchase Gift — " + product.priceLabel) {
                    guard draft.valid else { senderError = true; return }
                    focused = false
                    if auth.user == nil { signIn = true } else { checkoutNotice = true }
                }.buttonStyle(GiffyButtonStyle())
                Text(product.description).foregroundStyle(Brand.muted).lineSpacing(5).padding(.vertical, 16)
                if let asset = product.detailAsset { Image(asset).resizable().scaledToFit().frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 16)) }
                PreviewNotice()
            }.padding(20)
        }.background(.white).scrollDismissesKeyboard(.interactively)
            .navigationTitle("Gift details").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $signIn) { SignInView() }
            .alert("Checkout is not connected yet", isPresented: $checkoutNotice) { Button("OK", role: .cancel) {} } message: { Text("Your account is signed in. No payment has been created or charged.") }
    }
}

struct SignInView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Text("Sign in to Giffy").font(Brand.serif(24)); Spacer(); Button { auth.cancel(); dismiss() } label: { Image(systemName: "xmark").foregroundStyle(Brand.muted) }.accessibilityLabel("Close") }
            Button { auth.signIn(.google) } label: {
                HStack(spacing: 10) { GoogleMark().frame(width: 20, height: 20); Text("Continue with Google").font(Brand.body(14, .medium)) }.frame(maxWidth: .infinity).frame(height: 48).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.border))
            }.buttonStyle(.plain).disabled(auth.busy || auth.restoring)
            Button { auth.signIn(.apple) } label: { Label("Continue with Apple", systemImage: "apple.logo").font(Brand.body(14, .medium)).frame(maxWidth: .infinity).frame(height: 48).background(.black, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white) }.buttonStyle(.plain).disabled(auth.busy || auth.restoring)
            Text("Giffy will receive your name and email to create your account and manage your purchases.").font(Brand.body(12)).foregroundStyle(Color(hex: 0x78716C)).multilineTextAlignment(.center)
            HStack(spacing: 12) { Link("Terms of Service", destination: URL(string: "https://giffy-copy-85814e59.base44.app/terms")!); Link("Privacy Policy", destination: URL(string: "https://giffy-copy-85814e59.base44.app/privacy")!) }.font(Brand.body(12)).foregroundStyle(Brand.ink).frame(maxWidth: .infinity)
            if auth.busy || auth.restoring { ProgressView("Signing in…") }
            if let message = auth.errorMessage { Text(message).font(Brand.body(12)).foregroundStyle(.red).accessibilityLabel(message) }
        }.font(Brand.body(14)).foregroundStyle(Brand.ink).padding(28).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            .interactiveDismissDisabled(auth.busy)
            .onChange(of: auth.user?.id) { _, userID in if userID != nil { dismiss() } }
            .onDisappear { auth.cancel() }

    }
}

struct GoogleMark: View {
    var body: some View { Image("google").resizable().scaledToFit().accessibilityHidden(true) }
}
