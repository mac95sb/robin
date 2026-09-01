/// Content tangentially related to the surrounding content, such as a sidebar or pull quote.
///
/// `Aside` lowers to `<aside>`.
public struct Aside: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates an aside containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the aside's child components.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved aside and its child content.
  public var body: ComponentContent {
    .element(.aside, id: identifier, children: content.nodes)
  }
}
