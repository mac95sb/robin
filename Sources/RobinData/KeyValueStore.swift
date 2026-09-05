import Foundation

/// Durable namespaced key-value persistence.
public protocol KeyValueStore: Sendable {
  /// Writes bytes and an optional expiration time atomically.
  func put(
    _ value: Data,
    forKey key: String,
    namespace: String,
    expiresAt: Date?,
    condition: KeyValueWriteCondition
  ) async throws -> Bool

  /// Returns unexpired bytes for a key.
  func value(forKey key: String, namespace: String, at now: Date) async throws -> Data?

  /// Atomically removes and returns unexpired bytes for a key.
  func consumeValue(forKey key: String, namespace: String, at now: Date) async throws -> Data?

  /// Removes a key and reports whether it existed.
  func removeValue(forKey key: String, namespace: String) async throws -> Bool

  /// Removes at most `limit` expired entries.
  func removeExpired(at now: Date, limit: Int) async throws -> Int
}
