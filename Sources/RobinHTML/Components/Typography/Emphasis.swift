@_spi(Rendering) import RobinCore

/// Inline text with stress emphasis.
///
/// `Emphasis` lowers to `<em>` and always renders inline, regardless of its parent context.
public struct Emphasis: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates emphasized inline text.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the emphasized content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved emphasis element and its child content.
  public var body: ComponentContent {
    .element(.em, id: identifier, children: Text.phrasingContent(content.body).nodes)
  }
}
