@_spi(Rendering) import RobinCore

/// A collapsible disclosure widget with a summary label and hidden detail content.
///
/// `Disclosure` lowers to `<details><summary>...</summary>...</details>`.
public struct Disclosure: Component {
  private let isOpen: Bool
  private let identifier: String?
  private let label: ComponentContent
  private let content: ComponentContent

  /// Creates a disclosure widget with a summary label and detail content.
  ///
  /// - Parameters:
  ///   - open: Whether the detail content is visible without user interaction. The default is
  ///     `false`.
  ///   - id: An optional document-wide element identifier.
  ///   - label: A view builder that creates the always-visible summary label.
  ///   - content: A view builder that creates the collapsible detail content.
  public init(
    open: Bool = false,
    id: String? = nil,
    @ViewBuilder label: () -> ComponentContent,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.isOpen = open
    self.identifier = id
    self.label = label()
    self.content = content()
  }

  /// The resolved disclosure widget, its summary label, and its detail content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = []
    if isOpen { attributes.append(.open) }
    if let identifier { attributes.append(.identifier(identifier)) }
    let summary = RenderNode.element(
      RenderElement(kind: .summary, children: Text.phrasingContent(label.body).nodes)
    )
    return .node(
      .element(
        RenderElement(
          kind: .details,
          attributes: attributes,
          children: [summary] + content.nodes
        )
      )
    )
  }
}
