/// A normalized API root. Controllers declare paths relative to this value.
public struct APIPath: Equatable, Sendable {
  /// The normalized root-relative path beginning with `/`.
  public let value: String

  /// Creates a normalized API root.
  ///
  /// - Parameter value: A slash-delimited API root.
  /// - Throws: ``APIConfigurationError/invalidRoot(_:)`` when the path is empty or traverses.
  public init(_ value: String) throws {
    let segments = value.split(separator: "/", omittingEmptySubsequences: true)
    guard !segments.isEmpty, !segments.contains("."), !segments.contains("..") else {
      throw APIConfigurationError.invalidRoot(value)
    }
    self.value = "/" + segments.joined(separator: "/")
  }
}
