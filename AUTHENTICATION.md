# Base44 authentication

## Implementation
- Uses the same Giffy app ID and provider endpoints as @base44/sdk 0.8.57 loginWithProvider.
- Google and Apple run through ASWebAuthenticationSession, not an embedded WKWebView. Apple uses Base44's hosted Apple provider; no separate native Apple account database is introduced.
- Every attempt creates 32 random bytes of state. Only the active system authentication session consumes its exact callback scheme/host/path/state. Duplicate state/token parameters and unsolicited application URLs are rejected.
- Base44 returns its access token in the callback. The app verifies it against the original authenticated User/me API before establishing a local session. It does not treat email or an unverified JWT payload as proof of identity.
- Tokens are stored in Keychain with WhenUnlockedThisDeviceOnly accessibility, not UserDefaults, source files, or logs. HTTP responses use an ephemeral URLSession. No service-role credentials are shipped.
- The app revalidates stored credentials on restart. Expired credentials require sign-in again; the public SDK does not expose a refresh token contract for this flow.
- Logout cancels pending authentication, clears account state and removes the local Keychain credential. Authentication uses an ephemeral browser session so the app does not inherit the Base44 editor login.
- My Gifts uses the authenticated Purchase API, buyer_user_id filter, server RLS and a defensive owner check. Historical rows missing buyer_user_id are not automatically claimed by matching email.
- Existing web authentication and server configuration were not modified. Account linking across Google/Apple is Base44's responsibility; the app does not merge accounts by email.

## Verification and release gate
- Provider entry URLs and security-sensitive callback parser tested in Tests/AuthChecks.swift.
- Unauthenticated read-only probe confirms the Google entry endpoint forwards the custom return URL into the hosted OAuth flow. This is not proof that the final provider callback succeeds.
- A real Google and Apple sign-in must be completed by the account owner in the simulator/device to confirm callback delivery, server account verification and Keychain persistence. No fabricated callback or token counts as a live authentication test.
- If Base44 rejects the custom return URL after provider authentication, a supported hosted callback bridge is required before release. Do not bypass state validation or accept arbitrary deep links as a workaround.
- Test cancel, failure/retry, close during sign-in, app restart, logout and account switching. Check My Gifts against the same web account. Test Apple Hide My Email without automatic merging.
- Purchase remains explicitly disconnected and never starts a charge after sign-in.

## Run parser checks
From the repository root:

    swiftc Giffy/AuthConfiguration.swift Tests/AuthChecks.swift -o /tmp/giffy-auth-checks
    /tmp/giffy-auth-checks
