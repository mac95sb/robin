/// A language link whose route is preserved by the site preferences browser asset.
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

  /// The locale-root fallback link, enhanced to the current route by the preferences asset.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .a,
          attributes: [.href("/" + language.code), .languageLink(language.code)],
          children: content.nodes)))
  }
}
