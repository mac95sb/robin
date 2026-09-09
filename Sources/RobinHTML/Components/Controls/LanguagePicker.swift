/// A native dropdown that switches the leading locale segment of the current page URL.
///
/// Every language must have the same localized page routes.
///
/// HTML reference: [MDN: select](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/select).
public struct LanguagePicker: Component {
  /// A supported locale and its native display name.
  public struct Language: Sendable {
    /// The locale used as the first URL path segment.
    public let code: String
    /// The native language name shown in the dropdown.
    public let name: String

    /// Creates a language choice.
    /// - Parameters:
    ///   - code: An ASCII locale identifier using letters, digits, and hyphens.
    ///   - name: The visible native language name.
    public init(code: String, name: String) {
      precondition(
        !code.isEmpty
          && code.utf8.allSatisfy {
            (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45
          })
      self.code = code
      self.name = name
    }
  }

  private let languages: [Language]
  private let current: String
  private let label: String

  /// Creates a language dropdown.
  /// - Parameters:
  ///   - languages: The supported locales and their display names.
  ///   - current: The initially selected locale code.
  ///   - accessibilityLabel: The control's accessible name.
  public init(languages: [Language], current: String, accessibilityLabel: String = "Language") {
    precondition(!languages.isEmpty && languages.contains { $0.code == current })
    self.languages = languages
    self.current = current
    label = accessibilityLabel
  }

  /// The native select with the current locale selected.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .select, attributes: [.languagePicker, .accessibilityLabel(label)],
          children: languages.map { language in
            .element(
              RenderElement(
                kind: .option,
                attributes: [.value(language.code)] + (language.code == current ? [.selected] : []),
                children: [.text(language.name)]))
          })))
  }
}
