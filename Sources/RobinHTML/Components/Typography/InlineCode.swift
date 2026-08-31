@_spi(Rendering) import RobinCore

/// A short inline fragment of computer code.
///
/// `InlineCode` lowers to `<code>` and always renders inline, regardless of its parent context.
/// For multiline preformatted code, use ``CodeBlock`` instead.
public struct InlineCode: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates an inline code fragment.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the code fragment's content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved inline code element and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .code,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: Text.phrasingContent(content.body).nodes
        )
      )
    )
  }
}
