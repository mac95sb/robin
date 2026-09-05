/// A value-semantic, typed configuration collection.
public struct ConfigurationValues: Sendable {
  private var storage: [ObjectIdentifier: any Sendable] = [:]

  /// Creates an empty collection that resolves every key to its default value.
  public init() {}

  /// Accesses the value associated with a configuration key.
  ///
  /// Reading an unset key returns its declared default value.
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
