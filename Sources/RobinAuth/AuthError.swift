/// A public authentication failure that does not disclose account or credential state.
public enum AuthError: Error, Equatable, Sendable {
  /// Configuration is unsafe or internally inconsistent.
  case invalidConfiguration
  /// Caller input is malformed or unsafe.
  case invalidInput
  /// A passkey ceremony is absent, expired, cancelled, or already used.
  case invalidCeremony
  /// Credential verification failed.
  case invalidCredential
  /// A session is absent, expired, or revoked.
  case invalidSession
  /// The operation requires a more recent authentication.
  case recentAuthenticationRequired
  /// The configured recovery policy prevents removing the final passkey.
  case recoveryUnavailable
  /// An authentication-specific rate limit was exceeded.
  case rateLimited
  /// A redirect would leave the current application origin.
  case invalidRedirect
}
