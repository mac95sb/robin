@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle

/// A named component example rendered only by development tooling.
public struct Preview: Sendable {
  /// The preview's display name.
  public let name: String
  /// The category used to group the preview in a dashboard.
  public let category: String
  /// The named interaction, loading, or error state represented by the preview.
  public let state: String
  /// Optional documentation displayed alongside the preview.
  public let documentation: String?
  /// Checks run while generating the preview dashboard.
  public let checks: [PreviewCheck]
  let sourceFile: String
  let sourceLine: UInt
  private let content: ComponentContent

  /// Creates a preview from typed component content.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - category: A nonempty dashboard category.
  ///   - state: A nonempty interaction, loading, or error-state name.
  ///   - documentation: Optional preview-specific documentation.
  ///   - checks: Checks to run while generating the dashboard.
  ///   - sourceFile: The source file containing the preview declaration.
  ///   - sourceLine: The source line containing the preview declaration.
  ///   - content: Typed component content to render in isolated test state.
  public init(
    _ name: String = "Preview",
    category: String = "General",
    state: String = "Default",
    documentation: String? = nil,
    checks: [PreviewCheck] = [],
    sourceFile: StaticString = #filePath,
    sourceLine: UInt = #line,
    @ViewBuilder content: () -> ComponentContent
  ) {
    precondition(
      name.contains { !$0.isWhitespace } && category.contains { !$0.isWhitespace }
        && state.contains { !$0.isWhitespace }
    )
    self.name = name
    self.category = category
    self.state = state
    self.documentation = documentation
    self.checks = checks
    self.sourceFile = String(describing: sourceFile)
    self.sourceLine = sourceLine
    self.content = content()
  }

  /// Renders the preview's HTML body and generated CSS.
  ///
  /// - Parameters:
  ///   - theme: The design theme used to resolve style tokens.
  ///   - locale: The nonempty language identifier written to the preview document.
  /// - Returns: A complete HTML document for isolated preview display.
  /// - Throws: A render or style-compilation diagnostic.
  public func render(theme: Theme = .default, locale: String = "en") throws -> String {
    precondition(locale.contains { !$0.isWhitespace })
    let root = RenderNode.fragment(content.nodes)
    let styles = try StyleCompiler.compile(root, theme: theme, mode: .development)
    let body = try HTMLRenderer.render(root, styles: styles.className(for:))
    return
      "<!doctype html><html lang=\"\(HTMLRenderer.escape(locale))\"><head><meta charset=\"utf-8\"><style>\(styles.css)</style></head><body>\(body)</body></html>"
  }

  func accessibilityFindings() -> [AccessibilityFinding] {
    AccessibilityAudit.audit(content)
  }
}

/// Creates a typed Robin preview expression.
///
/// Use the result in a preview catalog or pass it directly to a ``PreviewDashboard``.
@freestanding(expression)
public macro Preview(
  _ name: String = "Preview",
  category: String = "General",
  state: String = "Default",
  documentation: String? = nil,
  checks: [PreviewCheck] = [],
  @ViewBuilder content: () -> ComponentContent
) -> Preview = #externalMacro(module: "RobinMacros", type: "PreviewMacro")
