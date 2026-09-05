import Crypto
import RobinCore

/// Whether a cached representation may be shared between users.
public enum CacheVisibility: Hashable, Sendable {
  /// Content that is safe to share.
  case shared
  /// Content visible only to one authenticated subject.
  case privateTo(String)
}
