/// A neutral, intent-based container for grouping and laying out child components.
///
/// `Stack` lowers to a neutral `div`. Apply typed RobinStyle layout modifiers to control direction,
/// spacing, flex, or grid behavior.
public struct Stack: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a stack containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the stack's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved neutral container and its child content.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .div,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: content.nodes
        )
      )
    )
  }
}
