/// A link to a locale root.
///
/// HTML reference: [MDN: a](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a).
public struct LanguageLink: Component {
  private let language: LanguagePicker.Language
  private let content: ComponentContent

  /// Creates a locale link with custom visible content.
  /// - Parameters:
  ///   - language: The supported destination locale.
  ///   - content: The link's visible label.
  public init(_ language: LanguagePicker.Language, @ViewBuilder content: () -> ComponentContent) {
    self.language = language
    self.content = content()
  }

  /// The locale-root link.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .a,
          attributes: [.href("/" + language.code), .languageLink(language.code)],
          children: content.nodes)))
  }
}
