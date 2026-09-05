import Foundation

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
