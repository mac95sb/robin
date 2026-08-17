import Foundation

/// An actor-isolated, codable key-value state store.
///
/// Values are JSON-encoded on write and decoded on read, so any `Codable` type
/// round-trips through the store. Actor isolation makes concurrent access safe
/// without locks.
public actor StateStore {
  private var values: [String: Data] = [:]

  /// Creates an empty state store.
  public init() {}

  /// Encodes and stores a value for a key.
  ///
  /// - Parameters:
  ///   - value: The value to store. Must be `Codable` and `Sendable`.
  ///   - key: The key to store the value under, replacing any previous value.
  /// - Throws: An encoding error if `value` cannot be JSON-encoded.
  public func set<Value: Codable & Sendable>(_ value: Value, forKey key: String) throws {
    values[key] = try JSONEncoder().encode(value)
  }

  /// Decodes the value stored for a key as the requested type.
  ///
  /// - Parameters:
  ///   - key: The key to look up.
  ///   - type: The type to decode the stored value as.
  /// - Returns: The decoded value, or `nil` when the key has no stored value.
  /// - Throws: A decoding error if the stored bytes are not valid for `Value`.
  public func value<Value: Codable & Sendable>(forKey key: String, as: Value.Type) throws -> Value?
  {
    guard let data = values[key] else { return nil }
    return try JSONDecoder().decode(Value.self, from: data)
  }
}
