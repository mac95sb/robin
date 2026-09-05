/// A tag used for grouped cache invalidation.
public struct CacheTag: Hashable, Sendable {
  /// The application-defined tag value.
  public let value: String

  /// Creates a cache tag.
  public init(_ value: String) {
    precondition(!value.isEmpty)
    self.value = value
  }
}
