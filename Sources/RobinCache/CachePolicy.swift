import Foundation

/// A cache duration expressed in seconds.
public struct CacheLifetime: Equatable, Sendable {
  package let seconds: TimeInterval

  /// Creates a duration in seconds.
  public static func seconds(_ value: TimeInterval) -> Self {
    precondition(value >= 0)
    return Self(seconds: value)
  }

  /// Creates a duration in minutes.
  public static func minutes(_ value: TimeInterval) -> Self { .seconds(value * 60) }
}

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

/// A tag used for grouped cache invalidation.
public struct CacheTag: Hashable, Sendable {
  /// The application-defined tag value.
  public let value: String

  /// Creates a cache tag.
  public init(_ value: String) {
    precondition(!value.isEmpty)
    self.value = value
  }
}
