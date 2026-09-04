/// A successful magic-link exchange.
public struct MagicLinkConsumption: Sendable {
  /// The verified or recovered account.
  public let account: Account
  /// Newly created authenticated session.
  public let session: SessionToken
  /// Validated same-origin redirect path.
  public let redirect: String
}
