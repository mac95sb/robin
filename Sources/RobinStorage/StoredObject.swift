/// A stored object's metadata and streaming body.
public struct StoredObject: Sendable {
  /// Persisted metadata.
  public let metadata: StorageMetadata
  /// Repeatable body stream.
  public let body: StorageBody
}
