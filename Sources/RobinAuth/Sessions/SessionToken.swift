import Foundation

/// An opaque bearer token returned after successful authentication.
public struct SessionToken: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
  /// Opaque value sent only in the secure session cookie.
  public let value: String
  /// Session expiration time.
  public let expiresAt: Date

  package init(value: String, expiresAt: Date) {
    self.value = value
    self.expiresAt = expiresAt
  }

  /// A redacted description that never reveals the bearer token.
  public var description: String { "<redacted>" }
  /// A redacted debug description that never reveals the bearer token.
  public var debugDescription: String { description }
}
