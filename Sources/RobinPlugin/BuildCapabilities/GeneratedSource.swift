/// One Swift source file emitted by a source-generating plugin.
public struct GeneratedSource: Equatable, Sendable {
  /// The path relative to the generated source root.
  public let path: String
  /// The UTF-8 Swift source.
  public let contents: String

  /// Creates a generated Swift source file.
  ///
  /// - Parameters:
  ///   - path: A nonempty relative path ending in `.swift`.
  ///   - contents: The UTF-8 Swift source.
  public init(path: String, contents: String) {
    let segments = path.split(separator: "/", omittingEmptySubsequences: false)
    precondition(
      !path.isEmpty && !path.hasPrefix("/") && !path.contains("\\") && path.hasSuffix(".swift")
        && segments.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
      "Generated source paths must be relative Swift file paths."
    )
    self.path = path
    self.contents = contents
  }
}
