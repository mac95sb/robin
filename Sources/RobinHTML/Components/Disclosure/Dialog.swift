/// A modal or non-modal dialog.
///
/// `Dialog` lowers to `<dialog>`.
public struct Dialog: Component {
  private let isOpen: Bool
  private let identifier: String?
  private let accessibilityLabel: String?
  private let content: ComponentContent

  /// Creates a dialog containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - open: Whether the dialog is visible without script-driven presentation. The default is
  ///     `false`.
  ///   - id: An optional document-wide element identifier.
  ///   - accessibilityLabel: An optional accessible name emitted as `aria-label`.
  ///   - content: A view builder that creates the dialog's content.
  public init(
    open: Bool = false,
    id: String? = nil,
    accessibilityLabel: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.isOpen = open
    self.identifier = id
    self.accessibilityLabel = accessibilityLabel
    self.content = content()
  }

  /// The resolved dialog and its child content.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = []
    if isOpen { attributes.append(.open) }
    if let identifier { attributes.append(.identifier(identifier)) }
    if let accessibilityLabel { attributes.append(.accessibilityLabel(accessibilityLabel)) }
    return .node(
      .element(RenderElement(kind: .dialog, attributes: attributes, children: content.nodes))
    )
  }
}
