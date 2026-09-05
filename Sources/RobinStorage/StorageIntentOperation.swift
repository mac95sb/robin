/// Operation authorized by a time-limited storage intent.
public enum StorageIntentOperation: Sendable {
  /// Upload one object.
  case upload(contentType: String, maximumBytes: Int64)
  /// Download one object.
  case download
}
