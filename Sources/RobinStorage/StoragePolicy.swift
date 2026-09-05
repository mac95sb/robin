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
