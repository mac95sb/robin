#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Errors produced by a W3C WebDriver test session.
public enum BrowserSessionError: Error, Equatable, Sendable {
  /// The WebDriver endpoint is not loopback-only HTTP.
  case unsafeEndpoint(String)
  /// The WebDriver response is malformed.
  case invalidResponse
  /// WebDriver rejected a command.
  case commandFailed(String)
  /// An element identifier cannot be represented by the constrained selector API.
  case invalidElementIdentifier(String)
  /// The selected browser cannot enforce the requested profile.
  case unsupportedProfile(String)
}
