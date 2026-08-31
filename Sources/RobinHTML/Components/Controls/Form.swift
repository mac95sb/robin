/// A form for collecting and submitting user input.
///
/// `Form` lowers to `<form action method>`.
public struct Form: Component {
  private let action: String?
  private let method: RenderElement.Attribute.FormMethod
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a form containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - action: The form's submission endpoint. `nil` submits to the current document.
  ///   - method: The form's submission method. The default is ``RenderElement/Attribute/FormMethod/post``.
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the form's fields and controls.
  public init(
    action: String? = nil,
    method: RenderElement.Attribute.FormMethod = .post,
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.action = action
    self.method = method
    self.identifier = id
    self.content = content()
  }

  /// The resolved form and its child content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.formMethod(method)]
    if let action { attributes.append(.action(action)) }
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(.element(.init(kind: .form, attributes: attributes, children: content.nodes)))
  }
}
