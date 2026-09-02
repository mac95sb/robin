/// A curated syntax-highlighting theme selected without handwritten CSS.
public enum SyntaxHighlightTheme: String, CaseIterable, Sendable {
  /// GitHub's light syntax palette.
  case github
  /// GitHub's dark syntax palette.
  case githubDark = "github-dark"
  /// The Solarized light syntax palette.
  case solarizedLight = "solarized-light"
  /// The Solarized dark syntax palette.
  case solarizedDark = "solarized-dark"
  /// Xcode's default light syntax palette.
  case xcodeDefault = "xcode-default"
  /// Xcode's default dark syntax palette.
  case xcodeDefaultDark = "xcode-default-dark"
}
