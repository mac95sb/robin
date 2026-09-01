@_spi(Rendering) import RobinCore

/// A caption for a form control.
///
/// `Label` lowers to `<label for>`, associating its text with the control whose `id` matches the
/// `for` attribute.
public struct Label: Component {
  private let target: String
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a label for a form control.
  ///
  /// - Parameters:
  ///   - target: The identifier of the control this label describes, serialized as `for`.
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the label's visible content.
  public init(
    for target: String,
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.target = target
    self.identifier = id
    self.content = content()
  }

  /// The resolved label and its child content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.labelFor(target)]
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(
      .element(
        RenderElement(
          kind: .label,
          attributes: attributes,
          children: Text.phrasingContent(content.body).nodes
        )
      )
    )
  }
}
