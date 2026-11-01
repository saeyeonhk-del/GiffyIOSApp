import Foundation

@main
struct AuthChecks {
    static func main() throws {
        let state = "random-state-for-tests"
        for provider in [AuthConfiguration.Provider.google, .apple] {
            let url = AuthConfiguration.loginURL(provider: provider, state: state)
            let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            precondition(url.scheme == "https" && url.host == "giffy-copy-85814e59.base44.app")
            let query = parts.queryItems!
            precondition(query.first(where: { $0.name == "app_id" })?.value == AuthConfiguration.appID)
            let callback = query.first(where: { $0.name == "from_url" })!.value!
            let hosted = URLComponents(string: callback)!
            precondition(hosted.scheme == "https" && hosted.host == "giffy-copy-85814e59.base44.app" && hosted.path == "/native-auth")
            let nativeReturn = AuthConfiguration.callbackScheme + "://callback?state=" + state
            let accepted = URL(string: nativeReturn + "&access_token=verified-by-server-later")!
            let acceptedToken = try AuthConfiguration.token(from: accepted, expectedState: state)
            precondition(acceptedToken == "verified-by-server-later")
            let fragment = URL(string: nativeReturn + "#access_token=fragment-token")!
            let fragmentToken = try AuthConfiguration.token(from: fragment, expectedState: state)
            precondition(fragmentToken == "fragment-token")
            for rejected in [nativeReturn + "&access_token=x&state=duplicate", nativeReturn + "&access_token=x&access_token=y", nativeReturn.replacingOccurrences(of: state, with: "wrong") + "&access_token=x", nativeReturn + "&access_token=", nativeReturn + "&access_token=bad%0Atoken", "https://evil.example/?state=" + state + "&access_token=x", AuthConfiguration.callbackScheme + "://other?state=" + state + "&access_token=x"] {
                do { _ = try AuthConfiguration.token(from: URL(string: rejected)!, expectedState: state); fatalError("Unsafe callback accepted") }
                catch AuthFailure.invalidCallback { }
            }
        }
        print("PASS: provider URLs, callback state binding, duplicate/replay-injection rejection and query/fragment parsing")
    }
}
