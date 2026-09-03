import Foundation
import RobinCore
import RobinHTML
import RobinStyle

/// A named theme available in a preview dashboard.
public struct PreviewTheme: Sendable {
  /// The theme's display name.
  public let name: String
  /// The Robin theme to render.
  public let theme: Theme

  /// Creates a named preview theme.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - theme: The theme to render.
  public init(_ name: String, theme: Theme) {
    precondition(name.contains { !$0.isWhitespace })
    self.name = name
    self.theme = theme
  }
}

/// A viewport offered by a preview dashboard.
public struct PreviewViewport: Equatable, Sendable {
  /// The viewport's display name.
  public let name: String
  /// The width in CSS pixels.
  public let width: Int
  /// The height in CSS pixels.
  public let height: Int

  /// Creates a preview viewport.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - width: A positive width in CSS pixels.
  ///   - height: A positive height in CSS pixels.
  public init(_ name: String, width: Int, height: Int) {
    precondition(name.contains { !$0.isWhitespace } && width > 0 && height > 0)
    self.name = name
    self.width = width
    self.height = height
  }
}

/// A color scheme offered by the preview dashboard.
public enum PreviewColorScheme: String, CaseIterable, Sendable {
  /// Prefer the theme's light palette.
  case light
  /// Prefer the theme's dark palette.
  case dark
}

/// Generates a local-only dashboard beneath `.robin/preview`.
public struct PreviewDashboard {
  /// Generates all requested preview, theme, viewport, and locale combinations.
  ///
  /// The dashboard's small filtering script remains in `.robin/preview`; it is never passed to the
  /// production artifact graph.
  ///
  /// - Parameters:
  ///   - previews: Component examples to display.
  ///   - themes: Named themes available to the dashboard.
  ///   - viewports: Viewport sizes available to the dashboard.
  ///   - locales: Nonempty locale identifiers available to the dashboard.
  ///   - colorSchemes: Light and dark modes available to the dashboard.
  ///   - layout: The project's generated-output layout.
  /// - Returns: The generated dashboard's `index.html` URL.
  /// - Throws: A rendering or file-system error.
  @discardableResult
  public static func generate(
    _ previews: [Preview],
    themes: [PreviewTheme] = [.init("Default", theme: .default)],
    viewports: [PreviewViewport] = [.init("Desktop", width: 1280, height: 800)],
    locales: [String] = ["en"],
    colorSchemes: [PreviewColorScheme] = PreviewColorScheme.allCases,
    in layout: OutputLayout
  ) throws -> URL {
    precondition(
      !themes.isEmpty && !viewports.isEmpty && !locales.isEmpty && !colorSchemes.isEmpty)
    precondition(locales.allSatisfy { $0.contains { !$0.isWhitespace } })
    let directory = layout.path(for: .preview)
    guard layout.contains(directory) else { throw SnapshotError.outputEscapesRobinRoot }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    var cards = ""
    for preview in previews {
      let accessibility = preview.accessibilityFindings()
      let checkResults = preview.checks.map { $0.result() }
      for theme in themes {
        for viewport in viewports {
          for locale in locales {
            for colorScheme in colorSchemes {
              cards += card(
                preview: preview,
                theme: theme.name,
                viewport: viewport,
                locale: locale,
                colorScheme: colorScheme,
                accessibility: accessibility,
                checkResults: checkResults,
                document: try preview.render(theme: theme.theme, locale: locale)
              )
            }
          }
        }
      }
    }
    let document = dashboard(
      cards: cards,
      themes: themes,
      viewports: viewports,
      locales: locales,
      colorSchemes: colorSchemes,
      states: Array(Set(previews.map(\.state))).sorted()
    )
    let output = directory.appendingPathComponent("index.html")
    try Data(document.utf8).write(to: output, options: .atomic)
    return output
  }

  private static func card(
    preview: Preview,
    theme: String,
    viewport: PreviewViewport,
    locale: String,
    colorScheme: PreviewColorScheme,
    accessibility: [AccessibilityFinding],
    checkResults: [PreviewCheckResult],
    document: String
  ) -> String {
    let source = Data(document.utf8).base64EncodedString()
    let accessibilityItems =
      accessibility.isEmpty
      ? "<li>Passed</li>"
      : accessibility.map { "<li><code>\(escape($0.code))</code> \(escape($0.message))</li>" }
        .joined()
    let checkItems = checkResults.map { result in
      switch result.outcome {
      case .passed: "<li>\(escape(result.name)): passed</li>"
      case .failed(let diagnostic):
        "<li>\(escape(result.name)): failed — \(escape(diagnostic))</li>"
      }
    }.joined()
    let documentation = preview.documentation.map { "<p>\(escape($0))</p>" } ?? ""
    return """
      <article data-theme="\(escape(theme))" data-viewport="\(escape(viewport.name))" data-locale="\(escape(locale))" data-scheme="\(colorScheme.rawValue)" data-state="\(escape(preview.state))"><h2>\(escape(preview.category)): \(escape(preview.name))</h2>\(documentation)<p>State: \(escape(preview.state)) · Source: <code>\(escape(preview.sourceFile)):\(preview.sourceLine)</code></p><iframe title="\(escape(preview.name))" lang="\(escape(locale))" style="width:\(viewport.width)px;height:\(viewport.height)px;color-scheme:\(colorScheme.rawValue)" src="data:text/html;base64,\(source)" sandbox></iframe><details><summary>Accessibility</summary><ul>\(accessibilityItems)</ul></details><details><summary>Tests</summary><ul>\(checkItems.isEmpty ? "<li>No associated checks</li>" : checkItems)</ul></details></article>
      """
  }

  private static func dashboard(
    cards: String,
    themes: [PreviewTheme],
    viewports: [PreviewViewport],
    locales: [String],
    colorSchemes: [PreviewColorScheme],
    states: [String]
  ) -> String {
    let themeOptions = themes.map { "<option>\(escape($0.name))</option>" }.joined()
    let viewportOptions = viewports.map { "<option>\(escape($0.name))</option>" }.joined()
    let localeOptions = locales.map { "<option>\(escape($0))</option>" }.joined()
    let schemeOptions = colorSchemes.map { "<option>\($0.rawValue)</option>" }.joined()
    let stateOptions = states.map { "<option>\(escape($0))</option>" }.joined()
    return """
      <!doctype html><html><head><meta charset="utf-8"><title>Robin Previews</title><style>body{font-family:system-ui;margin:1rem}nav{display:flex;gap:1rem;position:sticky;top:0;background:white;padding:.75rem 0}article{overflow:auto;margin:1rem 0}iframe{border:1px solid #ccc;max-width:100%}[hidden]{display:none}</style></head><body><h1>Robin Previews</h1><nav><label>Theme <select id="theme">\(themeOptions)</select></label><label>Viewport <select id="viewport">\(viewportOptions)</select></label><label>Locale <select id="locale">\(localeOptions)</select></label><label>Scheme <select id="scheme">\(schemeOptions)</select></label><label>State <select id="state">\(stateOptions)</select></label></nav><main>\(cards)</main><script>const ids=["theme","viewport","locale","scheme","state"],show=()=>document.querySelectorAll("article").forEach(card=>card.hidden=ids.some(id=>card.dataset[id]!==document.getElementById(id).value));ids.forEach(id=>document.getElementById(id).addEventListener("change",show));show()</script></body></html>
      """
  }

  private static func escape(_ value: String) -> String { HTMLRenderer.escape(value) }
}
