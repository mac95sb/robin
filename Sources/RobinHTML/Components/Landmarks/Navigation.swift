/// A section of links for navigating the site or page.
///
/// `Navigation` lowers to `<nav>`.
public struct Navigation: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a navigation landmark containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the navigation's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved navigation landmark and its child content.
  public var body: ComponentContent {
    .element(.nav, id: identifier, children: content.nodes)
  }
}
