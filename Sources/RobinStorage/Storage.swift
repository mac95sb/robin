import Foundation

/// Validation applied before an object becomes visible.
public struct StoragePolicy: Sendable {
  /// Accepted media types. An empty set accepts any type.
  public let contentTypes: Set<String>
  /// Maximum accepted body size.
  public let maximumBytes: Int64

  /// Creates an upload policy.
  public init(contentTypes: Set<String> = [], maximumBytes: Int64) {
    precondition(maximumBytes >= 0)
    self.contentTypes = contentTypes
    self.maximumBytes = maximumBytes
  }
}

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

/// Persisted object facts.
public struct StorageMetadata: Codable, Equatable, Sendable {
  /// Original normalized object key.
  public let key: String
  /// Tenant boundary.
  public let tenantIdentity: String
  /// Media type supplied at upload.
  public let contentType: String
  /// Body size in bytes.
  public let size: Int64
  /// Lowercase SHA-256 checksum.
  public let checksum: String
  /// Creation time.
  public let createdAt: Date
}

/// A stored object's metadata and streaming body.
public struct StoredObject: Sendable {
  /// Persisted metadata.
  public let metadata: StorageMetadata
  /// Repeatable body stream.
  public let body: StorageBody
}

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

/// Storage validation and lifecycle failures.
public enum StorageError: Error, Equatable, Sendable {
  /// An object key was empty, absolute, or contained traversal syntax.
  case invalidObjectKey(String)
  /// A local storage root must be an absolute file URL.
  case invalidRoot
  /// The declared media type is not allowed.
  case unsupportedContentType(String)
  /// The streamed body exceeded its size limit.
  case sizeLimitExceeded(Int64)
  /// The streamed body did not match its expected checksum.
  case checksumMismatch(expected: String, actual: String)
  /// Cleanup limits must be positive.
  case invalidCleanupLimit
  /// Stored metadata or content is incomplete.
  case corruptObject
  /// An S3-compatible endpoint returned an unsuccessful response.
  case providerResponse(Int)
  /// An S3-compatible response omitted required object metadata.
  case missingProviderMetadata
}
