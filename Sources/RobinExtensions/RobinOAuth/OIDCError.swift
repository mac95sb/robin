import Crypto
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// OpenID Connect failures that do not expose provider response bodies or credentials.
public enum OIDCError: Error, Equatable, Sendable {
  /// Provider configuration is incomplete or unsafe.
  case invalidConfiguration
  /// An operation received invalid input.
  case invalidInput
  /// The provider returned an unsuccessful HTTP status.
  case providerStatus(Int)
  /// The provider returned an unusable response.
  case invalidResponse
  /// Browser state was missing, expired, mismatched, or already consumed.
  case invalidState
}
