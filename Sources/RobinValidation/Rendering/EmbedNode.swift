public struct EmbedNode: Equatable, Sendable {
  public let source: String
  public let title: String

  public init(source: String, title: String) {
    self.source = source
    self.title = title
  }
}
