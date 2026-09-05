import Foundation

/// Provider-neutral local and S3-compatible object operations.
public protocol Storage: Sendable {
  /// Validates and atomically writes an object.
  func put(_ write: StorageWrite) async throws -> StorageMetadata
  /// Opens an object's metadata and body stream.
  func object(for key: ScopedObjectKey) async throws -> StoredObject?
  /// Removes an object and reports whether it existed.
  func remove(_ key: ScopedObjectKey) async throws -> Bool
  /// Removes at most `limit` objects older than the cutoff.
  func removeCreated(before cutoff: Date, limit: Int) async throws -> Int
}
