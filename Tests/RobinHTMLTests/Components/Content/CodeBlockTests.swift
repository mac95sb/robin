import RobinHTML
import Testing

@Suite("CodeBlock")
struct CodeBlockTests {
  @Test func codeBlockWrapsContentInNestedCodeElement() throws {
    let block = try HTMLRenderer.render(CodeBlock { "let x = 1" })

    #expect(block == "<pre><code>let x = 1</code></pre>")
  }

  @Test func highlightedCodeUsesTypedRegionsAndCuratedTheme() throws {
    let block = try HTMLRenderer.render(
      CodeBlock(language: "swift", theme: .xcodeDefaultDark) {
        CaseHighlight(.keyword) { "let" }
        " answer = "
        CaseHighlight(.number) { "42" }
      })

    #expect(
      block
        == #"<pre data-robin-highlight-theme="xcode-default-dark"><code data-robin-highlight-theme="xcode-default-dark" data-robin-language="swift"><span data-robin-highlight="keyword">let</span> answer = <span data-robin-highlight="number">42</span></code></pre>"#
    )
  }

  @Test func themeCatalogIncludesXcodeDefaults() {
    #expect(SyntaxHighlightTheme.allCases.contains(.xcodeDefault))
    #expect(SyntaxHighlightTheme.allCases.contains(.xcodeDefaultDark))
  }

  @Test func sharedHighlighterMergesPlainSourceAroundSemanticRuns() throws {
    let block = try HTMLRenderer.render(
      CodeBlock("let answer = call(42) // result", language: "swift", theme: .xcodeDefault))

    #expect(
      block
        == #"<pre data-robin-highlight-theme="xcode-default"><code data-robin-highlight-theme="xcode-default" data-robin-language="swift"><span data-robin-highlight="keyword">let</span> answer = <span data-robin-highlight="function">call</span>(<span data-robin-highlight="number">42</span>) <span data-robin-highlight="comment">// result</span></code></pre>"#
    )
  }
}

@Test func markupAndCSSHighlightingPreserveFormattedSource() {
  let html = "<!-- Example -->\n<input aria-label=\"Count\" value=\"0\">"
  let markup = SyntaxHighlighter.highlight(html, language: "html")
  #expect(markup.map(\.text).joined() == html)
  #expect(markup.contains { $0.kind == .type && $0.text == "input" })
  #expect(markup.contains { $0.kind == .attribute && $0.text == "aria-label" })
  #expect(markup.contains { $0.kind == .comment })
  let css = ".counter {\n  border-radius: 14px;\n}"
  let styles = SyntaxHighlighter.highlight(css, language: "css")
  #expect(styles.map(\.text).joined() == css)
  #expect(styles.contains { $0.kind == .property && $0.text == "border-radius" })
}
