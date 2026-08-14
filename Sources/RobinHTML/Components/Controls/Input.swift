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
    /// An absolute or relative URL.
    case url
    /// A telephone number.
    case telephone
  }

  private let kind: Kind
  private let name: String
  private let value: String?
  private let identifier: String?
  private let accessibilityLabel: String

  /// Creates a single-line input.
  ///
  /// - Parameters:
  ///   - kind: The kind of data accepted by the input. The default is ``Kind/text``.
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
    value: String? = nil,
    id: String? = nil,
    accessibilityLabel: String
  ) {
    self.kind = kind
    self.name = name
    self.value = value
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
  }

  /// The resolved structural content for the input.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [
      .name(name), .inputType(renderType), .accessibilityLabel(accessibilityLabel),
    ]
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
    case .url: .url
    case .telephone: .telephone
    }
  }
}
