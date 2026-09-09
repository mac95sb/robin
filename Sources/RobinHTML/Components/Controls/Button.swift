@_spi(Rendering) import RobinRuntime

/// A button component with a typed label and fixed structural attributes.
///
/// Configure identity, accessibility, and submission behavior when creating the button. The
/// label builder supplies the child components rendered inside the button element.
///
/// HTML reference: [MDN: button](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/button).
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

  private let action: StateAction?
  private let kind: Kind
  private let identifier: String?
  private let accessibilityLabel: String?
  private let command: PopoverCommand?
  private let content: ComponentContent

  /// Creates a button with the given structural attributes and content.
  ///
  /// - Parameters:
  ///   - kind: The button's form behavior. The default is ``Kind/button``.
  ///   - id: An optional document-wide element identifier.
  ///   - accessibilityLabel: An optional accessible name emitted as `aria-label`.
  ///   - action: An optional browser-local state operation. Use with the default button kind.
  ///   - command: An optional command that dismisses the enclosing ``Popover``. May accompany a
  ///     state action.
  ///   - content: A trailing view builder that creates the button's visible content.
  public init(
    _ kind: Kind = .button,
    id: String? = nil,
    accessibilityLabel: String? = nil,
    command: PopoverCommand? = nil,
    action: StateAction? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    precondition(
      action == nil || kind == .button,
      "State actions require a non-submitting button.")
    self.action = action
    self.kind = kind
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
    self.command = command
    self.content = content()
  }

  /// The resolved structural content for the button.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.buttonType(renderType)]
    if let action { attributes.append(.stateAction(action)) }
    if let command { attributes.append(.popoverCommand(command)) }
    if let identifier { attributes.append(.identifier(identifier)) }
    if let accessibilityLabel { attributes.append(.accessibilityLabel(accessibilityLabel)) }
    return .node(
      .element(
        .init(
          kind: .button,
          attributes: attributes,
          children: Text.phrasingContent(content.body).nodes
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
