/// A browser-readable double-submit token for authenticated state changes.
public struct CSRFToken: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
  /// Opaque value copied from the cookie into the `X-CSRF-Token` header.
  public let value: String

  /// Creates a fresh cryptographically random token.
  public init() { value = randomAuthToken() }

  /// A redacted description that never reveals the token.
  public var description: String { "<redacted>" }
  /// A redacted debug description that never reveals the token.
  public var debugDescription: String { description }
}
