/// A key for a typed Robin configuration value.
public protocol ConfigurationKey {
  /// The value stored for this key.
  associatedtype Value: Sendable
  /// The value returned when a scope has no override.
  static var defaultValue: Value { get }
}
