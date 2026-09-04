@_spi(Rendering) import RobinHTML

/// An inline Lucide icon.
///
/// Icons are decorative by default. Supply `accessibilityLabel` when the icon communicates meaning
/// that adjacent text does not already provide.
public struct Icon: Component {
  private let icon: LucideIcon
  private let size: Int
  private let accessibilityLabel: String?

  /// Creates an inline icon.
  ///
  /// - Parameters:
  ///   - icon: A generated icon from the ``LucideIcon`` catalog.
  ///   - size: The positive width and height in points.
  ///   - accessibilityLabel: A concise accessible name, or `nil` for a decorative icon.
  public init(
    _ icon: LucideIcon,
    size: Int = 24,
    accessibilityLabel: String? = nil
  ) {
    precondition(size > 0, "An icon's size must be positive.")
    self.icon = icon
    self.size = size
    self.accessibilityLabel = accessibilityLabel
  }

  /// The resolved inline vector element.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [
      .vectorWidth(String(size)),
      .vectorHeight(String(size)),
      .vectorViewBox("0 0 24 24"),
      .vectorFill("none"),
      .vectorStroke("currentColor"),
      .vectorStrokeWidth("2"),
      .vectorStrokeLineCap("round"),
      .vectorStrokeLineJoin("round"),
    ]
    if let accessibilityLabel {
      attributes += [.imageRole, .accessibilityLabel(accessibilityLabel)]
    } else {
      attributes.append(.accessibilityHidden)
    }
    return .node(
      .element(
        .init(
          kind: .svg,
          attributes: attributes,
          children: icon.nodes.map(\.renderNode)
        )))
  }
}
