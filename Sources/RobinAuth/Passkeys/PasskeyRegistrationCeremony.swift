import WebAuthn

/// Registration options paired with opaque server-side ceremony state.
public struct PasskeyRegistrationCeremony: Sendable {
  /// Opaque identifier returned with the browser credential.
  public let id: String
  /// Options encoded directly for `navigator.credentials.create()`.
  public let options: PublicKeyCredentialCreationOptions
}
