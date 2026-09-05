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
