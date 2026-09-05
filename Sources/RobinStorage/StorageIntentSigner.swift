import Foundation

/// Provider contract for direct signed uploads and downloads.
public protocol StorageIntentSigner: Sendable {
  /// Creates a signed direct-storage request.
  func intent(
    for key: ScopedObjectKey,
    operation: StorageIntentOperation,
    expiresAt: Date
  ) async throws -> SignedStorageIntent
}
