/// Input for a validated streaming object write.
public struct StorageWrite: Sendable {
  /// Tenant-aware destination key.
  public let key: ScopedObjectKey
  /// Declared media type.
  public let contentType: String
  /// Optional expected lowercase SHA-256 digest.
  public let expectedChecksum: String?
  /// Validation policy.
  public let policy: StoragePolicy
  /// Streaming body.
  public let body: StorageBody

  /// Creates an object write.
  public init(
    key: ScopedObjectKey,
    contentType: String,
    expectedChecksum: String? = nil,
    policy: StoragePolicy,
    body: StorageBody
  ) {
    self.key = key
    self.contentType = contentType
    self.expectedChecksum = expectedChecksum
    self.policy = policy
    self.body = body
  }
}
