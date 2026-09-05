/// Freshness and stale-serving policy for one cache entry.
public struct CachePolicy: Equatable, Sendable {
  /// How long an entry is fresh.
  public let freshness: CacheLifetime
  /// How long an expired entry may be served while it is refreshed.
  public let staleWhileRevalidate: CacheLifetime

  /// Creates a cache policy.
  public init(
    for freshness: CacheLifetime,
    staleWhileRevalidate: CacheLifetime = .seconds(0)
  ) {
    self.freshness = freshness
    self.staleWhileRevalidate = staleWhileRevalidate
  }
}
