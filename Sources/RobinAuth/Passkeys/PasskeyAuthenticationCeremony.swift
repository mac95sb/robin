import WebAuthn

/// Authentication options paired with opaque server-side ceremony state.
public struct PasskeyAuthenticationCeremony: Sendable {
  /// Opaque identifier returned with the browser assertion.
  public let id: String
  /// Options encoded directly for `navigator.credentials.get()`.
  public let options: PublicKeyCredentialRequestOptions
}
