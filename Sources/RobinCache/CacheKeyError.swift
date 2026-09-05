import Crypto
import RobinCore

/// Invalid cache-key input.
public enum CacheKeyError: Error, Equatable, Sendable {
  /// A required namespace or value was empty.
  case emptyComponent
}
