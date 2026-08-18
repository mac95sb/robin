/// Self-contained content that could be distributed or reused independently, such as a post or
/// comment.
///
/// `Article` lowers to `<article>`.
public struct Article: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates an article containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the article's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved article and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .article,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}
