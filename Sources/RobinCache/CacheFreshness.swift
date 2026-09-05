import Crypto
import RobinCore

/// Whether a cache hit is fresh or serviceable during background revalidation.
public enum CacheFreshness: Equatable, Sendable {
  /// The entry has not expired.
  case fresh
  /// The entry expired but remains inside its stale-while-revalidate window.
  case stale
}
