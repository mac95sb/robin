/// A key for a typed Robin configuration value.
public protocol ConfigurationKey {
  associatedtype Value: Sendable
  static var defaultValue: Value { get }
}

/// A value-semantic, typed configuration collection.
public struct ConfigurationValues: Sendable {
  private var storage: [ObjectIdentifier: any Sendable] = [:]

  public init() {}

  public subscript<Key: ConfigurationKey>(_ key: Key.Type) -> Key.Value {
    get { storage[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue }
    set { storage[ObjectIdentifier(key)] = newValue }
  }

  /// Returns a copy with a value overridden for a nested scope.
  public func setting<Key: ConfigurationKey>(_ key: Key.Type, to value: Key.Value) -> Self {
    var copy = self
    copy[key] = value
    return copy
  }
}
