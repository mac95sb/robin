/// The document's dominant, unique content.
///
/// `Main` lowers to `<main>`. A document should contain at most one `Main`.
///
/// HTML reference: [MDN: main](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/main).
public struct Main: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates the main landmark containing the components produced by a view builder.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the main content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved main landmark and its child content.
  public var body: ComponentContent {
    .element(.main, id: identifier, children: content.nodes)
  }
}
