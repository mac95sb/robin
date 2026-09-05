import Foundation

/// Raw cache storage shared by local and future distributed providers.
public protocol CacheStore: Sendable {
  /// Reads a record, including stale records that remain serviceable.
  func record(for key: String, at now: Date) async throws -> CacheRecord?
  /// Replaces a record.
  func store(_ record: CacheRecord, for key: String) async throws
  /// Removes one record.
  func remove(_ key: String) async throws
  /// Removes records bearing any supplied provider-facing tag.
  func invalidate(tags: Set<String>) async throws
  /// Removes every record.
  func removeAll() async throws
}
