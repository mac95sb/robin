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
        == #"<pre><code data-robin-highlight-theme="xcode-default-dark" data-robin-language="swift"><span data-robin-highlight="keyword">let</span> answer = <span data-robin-highlight="number">42</span></code></pre>"#
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
        == #"<pre><code data-robin-highlight-theme="xcode-default" data-robin-language="swift"><span data-robin-highlight="keyword">let</span> answer = <span data-robin-highlight="function">call</span>(<span data-robin-highlight="number">42</span>) <span data-robin-highlight="comment">// result</span></code></pre>"#
    )
  }
}
