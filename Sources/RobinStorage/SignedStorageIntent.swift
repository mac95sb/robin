import Foundation

/// Operation authorized by a time-limited storage intent.
public enum StorageIntentOperation: Sendable {
  /// Upload one object.
  case upload(contentType: String, maximumBytes: Int64)
  /// Download one object.
  case download
}

/// A time-limited direct object-storage request.
public struct SignedStorageIntent: Sendable {
  /// Signed destination.
  public let url: URL
  /// HTTP method to use.
  public let method: String
  /// Required request headers.
  public let headers: [String: String]
  /// Required multipart form fields for a signed POST upload.
  public let formFields: [String: String]
  /// Expiration time.
  public let expiresAt: Date

  /// Creates a signed storage request.
  public init(
    url: URL,
    method: String,
    headers: [String: String] = [:],
    formFields: [String: String] = [:],
    expiresAt: Date
  ) {
    self.url = url
    self.method = method
    self.headers = headers
    self.formFields = formFields
    self.expiresAt = expiresAt
  }
}

/// Provider contract for direct signed uploads and downloads.
public protocol StorageIntentSigner: Sendable {
  /// Creates a signed direct-storage request.
  func intent(
    for key: ScopedObjectKey,
    operation: StorageIntentOperation,
    expiresAt: Date
  ) async throws -> SignedStorageIntent
}
