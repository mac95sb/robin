import Foundation
import RobinCore
import RobinEmail

/// Opt-in email magic-link settings.
public struct MagicLinkConfiguration: Sendable {
  /// Application name used in the default message.
  public let applicationName: String
  /// Absolute HTTPS endpoint that consumes a token.
  public let callbackURL: URL
  /// Visible and envelope sender.
  public let sender: EmailAddress
  /// Token-signing secret.
  public let signingKey: Secret<Data>
  /// Maximum token lifetime.
  public let lifetime: TimeInterval

  /// Creates validated magic-link settings.
  ///
  /// - Parameters:
  ///   - applicationName: The nonempty name shown in the default email.
  ///   - callbackURL: The absolute HTTPS endpoint that consumes magic-link tokens.
  ///   - sender: The visible and envelope sender for the default message.
  ///   - signingKey: At least 32 bytes of secret key material.
  ///   - lifetime: The positive token lifetime, in seconds.
  /// - Throws: ``AuthError/invalidConfiguration`` when any setting is unsafe.
  public init(
    applicationName: String,
    callbackURL: URL,
    sender: EmailAddress,
    signingKey: Secret<Data>,
    lifetime: TimeInterval = 900
  ) throws {
    guard !applicationName.isEmpty, callbackURL.scheme == "https", callbackURL.host != nil,
      callbackURL.user == nil, callbackURL.password == nil, callbackURL.query == nil,
      callbackURL.fragment == nil, signingKey.withValue({ $0.count >= 32 }), lifetime.isFinite,
      lifetime > 0, lifetime <= TimeInterval(Int.max)
    else { throw AuthError.invalidConfiguration }
    self.applicationName = applicationName
    self.callbackURL = callbackURL
    self.sender = sender
    self.signingKey = signingKey
    self.lifetime = lifetime
  }
}
