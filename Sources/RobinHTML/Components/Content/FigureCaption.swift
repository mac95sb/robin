@_spi(Rendering) import RobinCore

/// The caption for a ``Figure``.
///
/// `FigureCaption` lowers to `<figcaption>`.
public struct FigureCaption: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a figure caption containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the caption's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved figure caption and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .figcaption,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: Text.phrasingContent(content.body).nodes
        )
      )
    )
  }
}
