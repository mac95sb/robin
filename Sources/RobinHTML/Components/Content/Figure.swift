/// Self-contained content, such as an image or diagram, with an optional ``FigureCaption``.
///
/// `Figure` lowers to `<figure>`.
public struct Figure: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a figure containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the figure's content, typically ending with a
  ///     ``FigureCaption``.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved figure and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .figure,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}
