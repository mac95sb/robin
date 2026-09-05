import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Polar client and webhook failures that are safe to surface without provider response bodies.
public enum PolarError: Error, Equatable, Sendable {
  /// Client configuration is incomplete or unsafe.
  case invalidConfiguration
  /// An operation received invalid input.
  case invalidInput
  /// Polar returned an unsuccessful status.
  case providerStatus(Int)
  /// Polar returned an unusable response.
  case invalidResponse
}
