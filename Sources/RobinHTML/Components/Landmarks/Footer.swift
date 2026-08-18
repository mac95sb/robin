/// Closing content for its nearest sectioning ancestor, such as authorship or related links.
///
/// `Footer` lowers to `<footer>`.
public struct Footer: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a footer landmark containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the footer's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved footer landmark and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .footer,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}
