/// One anchored heading in parsed content.
public struct TableOfContentsEntry: Equatable, Sendable {
  /// Heading depth from 1 through 6.
  public let level: Int
  /// Stable fragment identifier.
  public let id: String
  /// Plain heading label.
  public let title: String
}
