/// Durable key-value validation errors.
public enum KeyValueStoreError: Error, Equatable, Sendable {
  /// Cleanup limits must be positive.
  case invalidCleanupLimit(Int)
}
