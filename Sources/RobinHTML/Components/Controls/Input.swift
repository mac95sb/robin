@_spi(Rendering) import RobinRuntime

/// A typed single-line form input.
///
/// `Input` represents the shared semantic input primitive. Select the accepted data kind in the
/// initializer rather than choosing a different component type for each HTML input behavior.
public struct Input: Component {
  /// The kind of data accepted by the input.
  public enum Kind: String, Sendable {
    /// Unstructured single-line text.
    case text
    /// An email address.
    case email
    /// A password whose displayed value is obscured.
    case password
    /// A search query.
    case search
    /// A numeric value.
    case number
    /// A Boolean checkbox.
    case checkbox
    /// An absolute or relative URL.
    case url
    /// A telephone number.
    case telephone
  }

  var changeAction: StateAction?
  var inputAction: StateAction?
  private var state: StateReference?
  private let showsStepper: Bool
  private let kind: Kind
  private let name: String
  private let value: String?
  private let identifier: String?
  private let accessibilityLabel: String

  /// Creates a single-line input.
  ///
  /// - Parameters:
  ///   - kind: The kind of data accepted by the input. The default is ``Kind/text``.
  ///   - showsStepper: Whether a number input displays its native increment and decrement arrows.
  ///     Hiding them preserves numeric validation, editing, and keyboard controls. Other input kinds ignore this option.
  ///   - name: The form field name submitted with the input's value.
  ///   - value: An optional initial serialized value.
  ///   - id: An optional document-wide element identifier.
  ///   - accessibilityLabel: The accessible name emitted as `aria-label`.
  ///
  /// > Note: Form-schema integration will provide domain-value encoding and validation. This
  /// > foundation accepts the initial serialized value emitted into HTML.
  public init(
    _ kind: Kind = .text,
    name: String,
    showsStepper: Bool = true,
    value: String? = nil,
    id: String? = nil,
    accessibilityLabel: String
  ) {
    self.state = nil
    self.showsStepper = showsStepper
    self.kind = kind
    self.name = name
    self.value = value
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
  }

  /// Creates a two-way input binding to browser-local state.
  /// Numeric bindings reject empty, invalid, non-finite, and out-of-range integer edits without changing state.
  /// Boolean bindings render checkboxes; strings render text inputs.
  /// - Parameters:
  ///   - name: The submitted field name.
  ///   - value: The projected state declaration.
  ///   - showsStepper: Whether numeric inputs show their native arrows.
  ///   - id: An optional identifier for an associated label.
  ///   - accessibilityLabel: The input's accessible name.
  public init<Value: StateValue>(
    name: String, value: StateBinding<Value>, showsStepper: Bool = true,
    id: String? = nil, accessibilityLabel: String
  ) {
    let kind: Kind =
      switch Value.stateKind {
      case .boolean: .checkbox
      case .integer, .number: .number
      case .string: .text
      }
    self.init(
      kind, name: name, showsStepper: showsStepper,
      value: kind == .checkbox ? nil : value.reference.text,
      id: id, accessibilityLabel: accessibilityLabel)
    self.state = value.reference
  }

  /// The resolved structural content for the input.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [
      .name(name), .inputType(renderType), .accessibilityLabel(accessibilityLabel),
    ]
    if let changeAction { attributes.append(.stateOnChange(changeAction)) }
    if let inputAction { attributes.append(.stateOnInput(inputAction)) }
    if let state {
      attributes.append(.stateInput(state))
      if state.kind == .boolean && state.initial == "true" { attributes.append(.checked) }
      if state.kind == .number { attributes.append(.anyStep) }
    }
    if kind == .number && !showsStepper { attributes.append(.hiddenNumberStepper) }
    if let value { attributes.append(.value(value)) }
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(.element(.init(kind: .input, attributes: attributes)))
  }

  private var renderType: RenderElement.Attribute.InputType {
    switch kind {
    case .text: .text
    case .email: .email
    case .password: .password
    case .search: .search
    case .number: .number
    case .checkbox: .checkbox
    case .url: .url
    case .telephone: .telephone
    }
  }
}
