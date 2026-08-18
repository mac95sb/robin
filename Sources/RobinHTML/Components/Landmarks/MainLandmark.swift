/// The document's dominant, unique content.
///
/// `Main` lowers to `<main>`. A document should contain at most one `Main`.
public struct Main: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates the main landmark containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the main content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved main landmark and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .main,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}
