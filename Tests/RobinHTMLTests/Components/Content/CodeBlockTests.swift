import RobinHTML
import Testing

@Suite("CodeBlock")
struct CodeBlockTests {
  @Test func codeBlockWrapsContentInNestedCodeElement() throws {
    let block = try HTMLRenderer.render(CodeBlock { "let x = 1" })

    #expect(block == "<pre><code>let x = 1</code></pre>")
  }
}
