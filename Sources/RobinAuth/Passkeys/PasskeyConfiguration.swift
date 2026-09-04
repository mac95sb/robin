import Foundation
import WebAuthn

/// Relying-party and expiration settings for passkey ceremonies.
public struct PasskeyConfiguration: Sendable {
  /// Relying-party identifier without a scheme or port.
  public let relyingPartyID: String
  /// Human-readable relying-party name.
  public let relyingPartyName: String
  /// Exact HTTPS origin accepted from WebAuthn clients.
  public let origin: URL
  /// Maximum lifetime of a server-side challenge.
  public let challengeLifetime: TimeInterval
  /// Whether authenticators must verify the user locally.
  public let requireUserVerification: Bool

  /// Creates and validates passkey configuration.
  ///
  /// - Parameters:
  ///   - relyingPartyID: The effective domain accepted by authenticators, without a scheme or port.
  ///   - relyingPartyName: The nonempty name shown by authenticators.
  ///   - origin: The exact HTTPS application origin. HTTP is accepted only for local development.
  ///   - challengeLifetime: The positive server-side challenge lifetime, in seconds.
  ///   - requireUserVerification: Whether authenticators must verify the user locally.
  /// - Throws: ``AuthError/invalidConfiguration`` when the relying party, origin, or lifetime is
  ///   unsafe.
  public init(
    relyingPartyID: String,
    relyingPartyName: String,
    origin: URL,
    challengeLifetime: TimeInterval = 300,
    requireUserVerification: Bool = true
  ) throws {
    let host = origin.host?.lowercased()
    let id = relyingPartyID.lowercased()
    let localDevelopment = origin.scheme == "http" && (host == "localhost" || host == "127.0.0.1")
    guard !id.isEmpty, !relyingPartyName.isEmpty, challengeLifetime.isFinite,
      challengeLifetime > 0, challengeLifetime <= TimeInterval(Int64.max) / 1_000,
      id == "localhost" || id == "127.0.0.1" || id.contains("."),
      !id.contains(":"), !id.contains("/"), !id.contains(where: \.isWhitespace),
      origin.user == nil, origin.password == nil, origin.query == nil, origin.fragment == nil,
      origin.path.isEmpty || origin.path == "/",
      origin.scheme == "https" || localDevelopment,
      host == id || host?.hasSuffix(".\(id)") == true
    else { throw AuthError.invalidConfiguration }
    self.relyingPartyID = id
    self.relyingPartyName = relyingPartyName
    self.origin = origin
    self.challengeLifetime = challengeLifetime
    self.requireUserVerification = requireUserVerification
  }

  package var manager: WebAuthnManager {
    WebAuthnManager(
      configuration: .init(
        relyingPartyID: relyingPartyID,
        relyingPartyName: relyingPartyName,
        relyingPartyOrigin: origin.absoluteString.trimmingCharacters(
          in: CharacterSet(charactersIn: "/"))
      ))
  }
}
