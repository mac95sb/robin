import Crypto
import Foundation
import RobinCore

/// A decoded cache hit and its HTTP validators.
public struct CachedValue<Value: Sendable>: Sendable {
  /// The decoded application value.
  public let value: Value
  /// Current freshness state.
  public let freshness: CacheFreshness
  /// Entity tag for conditional requests.
  public let entityTag: String
  /// Source modification time for conditional requests.
  public let lastModified: Date
}
