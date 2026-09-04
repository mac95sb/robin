/// The account operation authorized by a magic link.
public enum MagicLinkPurpose: String, Codable, Equatable, Sendable {
  /// Sign in to an existing verified account.
  case signIn
  /// Create an account and verify its email association.
  case bootstrap
  /// Recover an existing verified account.
  case recovery
}
