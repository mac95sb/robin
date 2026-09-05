import Foundation

/// Provider-neutral encoded cache state.
public struct CacheRecord: Sendable {
  /// Encoded typed value.
  public let data: Data
  /// Time after which the entry is stale.
  public let expiresAt: Date
  /// Time after which the entry must not be served.
  public let staleUntil: Date
  /// Entity tag for conditional requests.
  public let entityTag: String
  /// Source modification time for conditional requests.
  public let lastModified: Date
  /// Provider-facing invalidation tags.
  public let tags: Set<String>

  /// Creates an encoded record for a cache provider.
  public init(
    data: Data,
    expiresAt: Date,
    staleUntil: Date,
    entityTag: String,
    lastModified: Date,
    tags: Set<String>
  ) {
    self.data = data
    self.expiresAt = expiresAt
    self.staleUntil = staleUntil
    self.entityTag = entityTag
    self.lastModified = lastModified
    self.tags = tags
  }
}
