@_spi(Rendering) import RobinCore

/// A semantic document heading.
///
/// Heading levels communicate document structure to browsers and assistive technologies. Supply a
/// string directly for ordinary content so it renders as bare heading text, such as
/// `<h1>Heading</h1>`. Use multiple nested ``Text`` values only when the heading intentionally
/// contains separately identifiable or stylable inline segments.
public struct Heading: Component {
  /// The semantic rank of a heading.
  public enum Level: Sendable {
    /// A top-level heading.
    case one
    /// A second-level heading.
    case two
    /// A third-level heading.
    case three
    /// A fourth-level heading.
    case four
    /// A fifth-level heading.
    case five
    /// A sixth-level heading.
    case six
  }

  private let level: Level
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a semantic heading.
  ///
  /// - Parameters:
  ///   - level: The heading's semantic rank. The default is ``Level/one``.
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates phrasing content for the heading. Direct strings
  ///     render as bare text; nested ``Text`` values render as inline segments.
  public init(
    _ level: Level = .one,
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.level = level
    self.identifier = id
    self.content = content()
  }

  /// The resolved structural content for the selected heading level.
  public var body: ComponentContent {
    ComponentContent.node(
      RenderNode.element(
        RenderElement(
          kind: elementKind,
          attributes: identifier.map { [.identifier($0)] } ?? [],
          children: Text.phrasingContent(content.body).nodes
        )
      )
    )
  }

  private var elementKind: RenderElement.Kind {
    switch level {
    case .one: .h1
    case .two: .h2
    case .three: .h3
    case .four: .h4
    case .five: .h5
    case .six: .h6
    }
  }
}
