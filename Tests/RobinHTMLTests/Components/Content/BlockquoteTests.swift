import RobinHTML
import Testing

@Suite("Blockquote")
struct BlockquoteTests {
  @Test func blockquoteLowersToBlockquoteElement() throws {
    let quote = try HTMLRenderer.render(Blockquote(id: "quote") { Text { "Words." } })

    #expect(quote == #"<blockquote id="quote"><p>Words.</p></blockquote>"#)
  }
}
