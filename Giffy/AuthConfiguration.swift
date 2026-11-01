import Foundation

enum AuthConfiguration {
    static let appID = "6a9569b7b335d09985814e59"
    static let baseURL = URL(string: "https://giffy-copy-85814e59.base44.app")!
    static let callbackScheme = "giffy-auth-6a9569b7b335d09985814e59"
    enum Provider: String { case google, apple }
    static func loginURL(provider: Provider, state: String) -> URL {
        var callback = URLComponents()
        callback = URLComponents(url: baseURL.appendingPathComponent("native-auth"), resolvingAgainstBaseURL: false)!
        callback.queryItems = [URLQueryItem(name: "state", value: state)]
        // Same endpoint and parameters as Base44's official loginWithProvider SDK.
        let path = provider == .google ? "/api/apps/auth/login" : "/api/apps/auth/apple/login"
        var url = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        url.queryItems = [URLQueryItem(name: "app_id", value: appID), URLQueryItem(name: "from_url", value: callback.url!.absoluteString)]
        return url.url!
    }
    static func token(from url: URL, expectedState: String) throws -> String {
        guard url.scheme == callbackScheme, url.host == "callback", url.path.isEmpty || url.path == "/",
              url.user == nil, url.password == nil, url.port == nil,
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw AuthFailure.invalidCallback }
        var items = parts.queryItems ?? []
        if let fragment = parts.fragment { items += URLComponents(string: "https://callback.invalid/?" + fragment)?.queryItems ?? [] }
        let states = items.filter { $0.name == "state" }
        let tokens = items.filter { $0.name == "access_token" }
        guard states.count == 1, states[0].value == expectedState, !expectedState.isEmpty,
              tokens.count == 1, let token = tokens[0].value, !token.isEmpty, token.count < 32768,
              !token.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.union(.controlCharacters).contains($0) }) else { throw AuthFailure.invalidCallback }
        return token
    }
}

enum AuthFailure: Error, LocalizedError {
    case invalidCallback, noWindow, cannotStart, unauthorized, server, storage
    var errorDescription: String? {
        switch self {
        case .invalidCallback: "The sign-in response could not be verified. Please try again."
        case .noWindow, .cannotStart: "Sign-in could not open. Please try again."
        case .unauthorized: "Your session has expired. Please sign in again."
        case .server: "Giffy could not be reached. Please check your connection and retry."
        case .storage: "Your sign-in could not be saved securely. Please try again."
        }
    }
}
