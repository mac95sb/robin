import Foundation

/// A persisted WebAuthn credential owned by one account.
public struct PasskeyCredential: Codable, Equatable, Sendable {
  /// Base64url credential identifier.
  public let id: String
  /// Owning account identifier.
  public let accountID: String
  /// COSE-encoded public key bytes.
  public let publicKey: Data
  /// Authenticator signature counter.
  public package(set) var signCount: UInt32
  /// Whether the credential may be backed up.
  public let backupEligible: Bool
  /// Whether the credential is currently backed up.
  public package(set) var isBackedUp: Bool
  /// User-visible credential label.
  public package(set) var name: String
  /// Registration time.
  public let createdAt: Date
  /// Most recent successful use.
  public package(set) var lastUsedAt: Date?
}
