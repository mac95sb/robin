import Crypto
import RobinCore

/// Observable cache operations.
public enum CacheEvent: Equatable, Sendable {
  /// A key was not found.
  case miss(String)
  /// A fresh key was found.
  case hit(String)
  /// A stale key was found.
  case stale(String)
  /// A key was stored.
  case stored(String)
  /// Tags were invalidated.
  case invalidated(Int)
  /// A provider or encoding operation failed for a key.
  case failed(String)
}
