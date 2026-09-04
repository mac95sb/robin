import Foundation

/// Validated durable session state.
public struct AuthSession: Codable, Equatable, Sendable {
  /// Stable account identifier.
  public let accountID: String
  /// Session creation time.
  public let createdAt: Date
  /// Time of the authentication ceremony that created or refreshed the session.
  public let authenticatedAt: Date
  /// Session expiration time.
  public let expiresAt: Date
}
