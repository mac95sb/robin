@_spi(Rendering) import RobinCore

/// Inline text of strong importance.
///
/// `Strong` lowers to `<strong>` and always renders inline, regardless of its parent context.
///
/// HTML reference: [MDN: strong](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/strong).
public struct Strong: Component {
  private let identifier: String?
  private let content: ComponentContent

  /// Creates strongly emphasized inline text.
  ///
  /// - Parameters:
  ///   - id: An optional document-wide element identifier.
  ///   - content: A view builder that creates the strongly emphasized content.
  public init(
    id: String? = nil,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.identifier = id
    self.content = content()
  }

  /// The resolved strong element and its child content.
  public var body: ComponentContent {
    .element(.strong, id: identifier, children: Text.phrasingContent(content.body).nodes)
  }
}
