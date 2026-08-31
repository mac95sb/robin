@_spi(Rendering) import RobinCore

/// Semantic text content whose rendered structure is inferred from its parent.
///
/// At flow level, `Text` renders as a paragraph. Phrasing-only parents such as ``Heading`` and
/// ``Button`` adapt nested `Text` values to inline spans. A direct string expression inside a heading
/// remains a bare text node, so ordinary heading content does not gain a redundant span. Text values
/// are escaped when emitted as HTML.
public struct Text: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates semantic text content.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the text content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The paragraph content that a phrasing-only parent adapts to its required inline structure.
  public var body: ComponentContent {
    ComponentContent.node(
      RenderNode.element(
        RenderElement(
          kind: .p,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}

extension Text {
  /// Adapts paragraph text to inline spans for a parent that accepts only phrasing content.
  ///
  /// - Parameter content: The resolved child content to adapt.
  /// - Returns: Phrasing content with top-level paragraphs represented as inline spans.
  static func phrasingContent(_ content: ComponentContent) -> ComponentContent {
    content.mapTopLevelElements { element in
      guard element.kind == .p else { return element }
      return RenderElement(
        kind: .span,
        attributes: element.attributes,
        styles: element.styles,
        children: element.children
      )
    }
  }
}
