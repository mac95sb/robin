import RobinHTML
import Testing

@Suite("InlineCode")
struct InlineCodeTests {
  @Test func inlineCodeLowersToCodeElement() throws {
    let code = try HTMLRenderer.render(InlineCode { "let x = 1" })

    #expect(code == "<code>let x = 1</code>")
  }
}
