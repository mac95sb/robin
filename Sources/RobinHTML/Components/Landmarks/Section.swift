/// A generic, thematic grouping of content, typically with a heading.
///
/// `Section` lowers to `<section>`. Prefer a more specific landmark (``Article``, ``Aside``,
/// ``Navigation``) when one applies; use `Section` for thematic groupings that don't fit those
/// roles.
public struct Section: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a section containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the section's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved section and its child content.
  public var body: ComponentContent {
    .element(.section, id: identifier, children: content.nodes)
  }
}
