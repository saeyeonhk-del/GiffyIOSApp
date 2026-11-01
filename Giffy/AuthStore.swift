import SwiftUI
import AuthenticationServices
import Security

struct GiffyUser: Decodable, Identifiable {
    let id: String
    let email: String
    let full_name: String?
}

private enum SecureSession {
    static let service = "com.giffy.session"
    static let account = AuthConfiguration.appID
    static var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account] }
    static func read() -> String? {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ token: String) throws {
        let data = Data(token.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw AuthFailure.storage }
        var q = query; q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(q as CFDictionary, nil) == errSecSuccess else { throw AuthFailure.storage }
    }
    static func clear() { SecItemDelete(query as CFDictionary) }
}

@MainActor
final class AuthStore: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published private(set) var user: GiffyUser?
    @Published private(set) var busy = false
    @Published private(set) var restoring = false
    @Published var errorMessage: String?
    private var session: ASWebAuthenticationSession?
    private var token: String?
    private var attempt: UUID?
    private var restored = false
    private let network = URLSession(configuration: .ephemeral)

    func restore() async {
        guard !restored else { return }; restored = true
        guard let stored = SecureSession.read() else { return }
        restoring = true; defer { restoring = false }
        let operation = UUID(); attempt = operation
        do {
            let verified = try await verify(stored)
            guard attempt == operation else { return }
            token = stored; user = verified
        } catch {
            guard attempt == operation else { return }
            if case AuthFailure.unauthorized = error { SecureSession.clear() }
            errorMessage = (error as? AuthFailure)?.errorDescription ?? "Unable to restore your session. Please sign in again."
        }
    }
    func signIn(_ provider: AuthConfiguration.Provider) {
        guard !busy, !restoring else { return }
        errorMessage = nil
        guard UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).contains(where: \.isKeyWindow) else { errorMessage = AuthFailure.noWindow.errorDescription; return }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { errorMessage = AuthFailure.cannotStart.errorDescription; return }
        let state = Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        let operation = UUID(); attempt = operation; busy = true
        let authSession = ASWebAuthenticationSession(url: AuthConfiguration.loginURL(provider: provider, state: state), callbackURLScheme: AuthConfiguration.callbackScheme) { [weak self] url, error in
            Task { @MainActor [weak self] in
                guard let self, self.attempt == operation else { return }
                self.session = nil
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin { self.busy = false; return }
                guard error == nil, let url else { self.busy = false; self.errorMessage = AuthFailure.cannotStart.errorDescription; return }
                do {
                    let token = try AuthConfiguration.token(from: url, expectedState: state)
                    let user = try await self.verify(token)
                    guard self.attempt == operation else { return }
                    try SecureSession.save(token)
                    self.token = token; self.user = user; self.busy = false
                } catch {
                    guard self.attempt == operation else { return }
                    self.busy = false
                    self.errorMessage = (error as? AuthFailure)?.errorDescription ?? "Sign-in failed. Please check your connection and retry."
                }
            }
        }
        authSession.presentationContextProvider = self
        // Do not import an editor's existing Base44 browser session into the buyer app.
        authSession.prefersEphemeralWebBrowserSession = true
        session = authSession
        if !authSession.start() { session = nil; busy = false; errorMessage = AuthFailure.cannotStart.errorDescription }
    }
    func cancel() {
        attempt = nil; session?.cancel(); session = nil; busy = false
    }
    func signOut() {
        cancel(); token = nil; user = nil; errorMessage = nil; SecureSession.clear()
    }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
    private func verify(_ token: String) async throws -> GiffyUser {
        let data = try await request("User/me", token: token)
        guard let user = try? JSONDecoder().decode(GiffyUser.self, from: data), !user.id.isEmpty else { throw AuthFailure.server }
        return user
    }
    private func request(_ entity: String, token: String, query: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(url: AuthConfiguration.baseURL.appendingPathComponent("api/apps/\(AuthConfiguration.appID)/entities/\(entity)"), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query
        var request = URLRequest(url: components.url!); request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await network.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw AuthFailure.server }
        if response.statusCode == 401 { throw AuthFailure.unauthorized }
        guard response.statusCode == 200 else { throw AuthFailure.server }
        return data
    }
    func myGifts() async throws -> [PurchasedGift] {
        guard let user, let token else { throw AuthFailure.unauthorized }
        let owner = user.id
        let filter = String(data: try JSONEncoder().encode(["buyer_user_id": owner]), encoding: .utf8)!
        do {
            let data = try await request("Purchase", token: token, query: [.init(name: "q", value: filter), .init(name: "sort", value: "-created_date")])
            let gifts = try JSONDecoder().decode([PurchasedGift].self, from: data)
            // Defensive check in addition to server-side RLS and the owner filter.
            guard self.user?.id == owner, self.token == token else { throw CancellationError() }
            return gifts.filter { $0.buyer_user_id == owner }
        } catch AuthFailure.unauthorized {
            if self.token == token { signOut(); errorMessage = AuthFailure.unauthorized.errorDescription }
            throw AuthFailure.unauthorized
        }
    }
}

struct PurchasedGift: Decodable, Identifiable {
    let id: String
    let buyer_user_id: String?
    let product_name: String?
    let vendor_name: String?
    let amount: Double?
    let gift_code: String?
    let status: String?
}
