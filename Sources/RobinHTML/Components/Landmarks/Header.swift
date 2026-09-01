/// Introductory or navigational content for its nearest sectioning ancestor.
///
/// `Header` lowers to `<header>`. Use it for a page or section's introductory content, such as a
/// heading group, logo, or search form.
public struct Header: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a header landmark containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the header's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved header landmark and its child content.
  public var body: ComponentContent {
    .element(.header, id: identifier, children: content.nodes)
  }
}
