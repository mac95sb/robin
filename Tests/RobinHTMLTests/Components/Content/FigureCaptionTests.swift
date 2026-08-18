import RobinHTML
import Testing

@Suite("FigureCaption")
struct FigureCaptionTests {
  @Test func nestedTextAdaptsToPhrasingContent() throws {
    let caption = try HTMLRenderer.render(FigureCaption { Text { "Caption" } })

    #expect(caption == "<figcaption><span>Caption</span></figcaption>")
  }
}
