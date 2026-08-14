import Foundation

/// An actor-isolated, codable key-value state store.
public actor StateStore {
  private var values: [String: Data] = [:]

  public init() {}

  /// Encodes and stores a value for a key.
  public func set<Value: Codable & Sendable>(_ value: Value, forKey key: String) throws {
    values[key] = try JSONEncoder().encode(value)
  }

  /// Decodes the value stored for a key as the requested type.
  public func value<Value: Codable & Sendable>(forKey key: String, as: Value.Type) throws -> Value?
  {
    guard let data = values[key] else { return nil }
    return try JSONDecoder().decode(Value.self, from: data)
  }
}
