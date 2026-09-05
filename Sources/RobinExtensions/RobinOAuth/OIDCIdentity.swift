import Crypto
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Verified identity returned by an OpenID Connect provider.
public struct OIDCIdentity: Equatable, Sendable {
  /// Provider-stable subject identifier.
  public let subject: String
  /// Optional display name.
  public let name: String?
  /// Email address only when the provider reported it as verified.
  public let verifiedEmail: String?
}
