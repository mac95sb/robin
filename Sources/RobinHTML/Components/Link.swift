@_spi(Rendering) import RobinCore

/// A hyperlink to another document or location.
///
/// `Link` lowers to `<a href>`. Its content adapts to phrasing context the same way ``Text``
/// does: a direct string renders as bare text, while nested ``Text`` values render as inline
/// segments.
public struct Link: Component {
  private let destination: String
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a hyperlink to a destination.
  ///
  /// - Parameters:
  ///   - destination: The link's target, serialized as `href`.
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the link's visible content.
  public init(
    _ destination: String,
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.destination = destination
    self.identifier = id
    self.content = content()
  }

  /// The resolved hyperlink and its child content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.href(destination)]
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(
      .element(
        RenderElement(
          kind: .a,
          attributes: attributes,
          children: Text.phrasingContent(content.body).nodes
        )
      )
    )
  }
}
