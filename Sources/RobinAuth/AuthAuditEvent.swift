import Foundation

/// Redacted authentication facts safe for application audit logs.
public struct AuthAuditEvent: Equatable, Sendable {
  /// Authentication event category.
  public enum Kind: Equatable, Sendable {
    /// A passkey registration completed.
    case passkeyRegistered
    /// A passkey authentication completed.
    case passkeyAuthenticated
    /// A passkey was removed.
    case passkeyRemoved
    /// A session was created.
    case sessionCreated
    /// A session was revoked.
    case sessionRevoked
    /// A magic link was requested without revealing account existence.
    case magicLinkRequested
    /// A magic link was consumed.
    case magicLinkConsumed
    /// An authentication rate limit rejected an attempt.
    case rateLimited
  }

  /// Event category.
  public let kind: Kind
  /// Stable account identifier when authenticated; never an email address or token.
  public let accountID: String?
  /// Event time.
  public let occurredAt: Date
}
