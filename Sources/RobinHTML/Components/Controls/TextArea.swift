/// A multiline plain-text form control.
///
/// `TextArea` lowers to `<textarea>`, with its initial value as text content.
public struct TextArea: Component {
  private let name: String
  private let value: String?
  private let identifier: String?
  private let accessibilityLabel: String

  /// Creates a multiline text input.
  ///
  /// - Parameters:
  ///   - name: The form field name submitted with the control's value.
  ///   - value: An optional initial serialized value.
  ///   - id: An optional document-wide element identifier.
  ///   - accessibilityLabel: The accessible name emitted as `aria-label`.
  public init(
    name: String,
    value: String? = nil,
    id: String? = nil,
    accessibilityLabel: String
  ) {
    self.name = name
    self.value = value
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
  }

  /// The resolved text area and its initial value as text content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [
      .name(name), .accessibilityLabel(accessibilityLabel),
    ]
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(
      .element(
        RenderElement(
          kind: .textarea,
          attributes: attributes,
          children: value.map { [.text($0)] } ?? []
        )
      )
    )
  }
}
