/// A curated syntax-highlighting theme selected without handwritten CSS.
public enum SyntaxHighlightTheme: String, CaseIterable, Hashable, Sendable {
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

  package var stylesheet: String {
    let palette: Palette =
      switch self {
      case .github:
        .init(
          "#f6f8fa", "#24292f", "#6e7781", "#cf222e", "#0a3069", "#0550ae", "#953800", "#8250df",
          "#116329")
      case .githubDark:
        .init(
          "#161b22", "#c9d1d9", "#8b949e", "#ff7b72", "#a5d6ff", "#79c0ff", "#ffa657", "#d2a8ff",
          "#7ee787")
      case .solarizedLight:
        .init(
          "#fdf6e3", "#657b83", "#93a1a1", "#859900", "#2aa198", "#d33682", "#b58900", "#268bd2",
          "#6c71c4")
      case .solarizedDark:
        .init(
          "#002b36", "#839496", "#586e75", "#859900", "#2aa198", "#d33682", "#b58900", "#268bd2",
          "#6c71c4")
      case .xcodeDefault:
        .init(
          "#ffffff", "#000000", "#5d6c79", "#ad3da4", "#d12f1b", "#272ad8", "#703daa", "#326d74",
          "#4b21b0")
      case .xcodeDefaultDark:
        .init(
          "#1f1f24", "#ffffff", "#7f8c98", "#ff7ab2", "#ff8170", "#d9c97c", "#dabaff", "#6bdfff",
          "#b281eb")
      }
    let root = "[data-robin-highlight-theme=\"\(rawValue)\"]"
    return [
      "\(root){background:\(palette.background);color:\(palette.foreground)}",
      rule("attribute", palette.property, root),
      rule("comment", palette.comment, root),
      rule("function", palette.function, root),
      rule("keyword", palette.keyword, root),
      rule("literal", palette.number, root),
      rule("number", palette.number, root),
      rule("property", palette.property, root),
      rule("string", palette.string, root),
      rule("type", palette.type, root),
    ].joined()
  }

  private func rule(_ kind: String, _ color: String, _ root: String) -> String {
    "\(root) [data-robin-highlight=\"\(kind)\"]{color:\(color)}"
  }
}

private struct Palette {
  let background: String
  let foreground: String
  let comment: String
  let keyword: String
  let string: String
  let number: String
  let type: String
  let function: String
  let property: String

  init(
    _ background: String, _ foreground: String, _ comment: String, _ keyword: String,
    _ string: String, _ number: String, _ type: String, _ function: String, _ property: String
  ) {
    self.background = background
    self.foreground = foreground
    self.comment = comment
    self.keyword = keyword
    self.string = string
    self.number = number
    self.type = type
    self.function = function
    self.property = property
  }
}
