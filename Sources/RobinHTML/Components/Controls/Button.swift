/// A button component with a typed label and fixed structural attributes.
///
/// Configure identity, accessibility, and submission behavior when creating the button. The
/// label builder supplies the child components rendered inside the button element.
public struct Button: Component {
  /// The button's form behavior.
  public enum Kind: String, Sendable {
    /// A button with no default form-submission behavior.
    case button
    /// A button that submits its associated form.
    case submit
    /// A button that resets its associated form.
    case reset
  }

  private let kind: Kind
  private let identifier: String?
  private let accessibilityLabel: String?
  private let label: ComponentContent

  /// Creates a button with the given structural attributes and label.
  ///
  /// - Parameters:
  ///   - kind: The button's form behavior. The default is ``Kind/button``.
  ///   - id: An optional document-wide element identifier.
  ///   - accessibilityLabel: An optional accessible name emitted as `aria-label`.
  ///   - label: A view builder that creates the button's visible label content.
  public init(
    _ kind: Kind = .button,
    id: String? = nil,
    accessibilityLabel: String? = nil,
    @ViewBuilder label: () -> ComponentContent
  ) {
    self.kind = kind
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
    self.label = label()
  }

  /// The resolved structural content for the button.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.buttonType(renderType)]
    if let identifier { attributes.append(.identifier(identifier)) }
    if let accessibilityLabel { attributes.append(.accessibilityLabel(accessibilityLabel)) }
    return .node(
      .element(
        .init(
          kind: .button,
          attributes: attributes,
          children: Text.phrasingContent(label.body).nodes
        )
      )
    )
  }

  private var renderType: RenderElement.Attribute.ButtonType {
    switch kind {
    case .button: .button
    case .submit: .submit
    case .reset: .reset
    }
  }
}
