import RobinHTML
import Testing

@Suite("Text")
struct TextTests {
  @Test func textLowersToParagraphHTMLInFlowContent() throws {
    let paragraph = try HTMLRenderer.render(Text(id: "detail") { "Hello & goodbye" })

    #expect(paragraph == #"<p id="detail">Hello &amp; goodbye</p>"#)
  }
}
