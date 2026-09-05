import Foundation

/// Persisted object facts.
public struct StorageMetadata: Codable, Equatable, Sendable {
  /// Original normalized object key.
  public let key: String
  /// Tenant boundary.
  public let tenantIdentity: String
  /// Media type supplied at upload.
  public let contentType: String
  /// Body size in bytes.
  public let size: Int64
  /// Lowercase SHA-256 checksum.
  public let checksum: String
  /// Creation time.
  public let createdAt: Date
}
