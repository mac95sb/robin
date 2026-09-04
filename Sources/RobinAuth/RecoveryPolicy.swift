/// Account recovery methods allowed by an authentication configuration.
public enum RecoveryPolicy: Equatable, Sendable {
  /// Recovery requires another registered passkey.
  case passkeysOnly
  /// A verified email address may recover the account through a magic link.
  case magicLink
}
