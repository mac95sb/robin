import Testing

@testable import RobinValidation

@Suite("HTML renderer")
struct HTMLRendererTests {
  @Test func representativePageRenderingIsDeterministic() {
    let page = RepresentativePage(includeFooter: true).resolve()
    let first = HTMLRenderer.render(page)
    let second = HTMLRenderer.render(page)

    #expect(first == second)
    #expect(first.components(separatedBy: "<article>").count - 1 == 48)
    #expect(first.contains("&lt;is escaped&gt;"))
    #expect(first.contains("<footer>Measured prototype</footer>"))
  }

  @Test func embedRenderingIsSandboxed() {
    let embed = RenderNode.embed(.init(source: "https://example.com/video", title: "Video"))

    #expect(HTMLRenderer.render(embed).contains("sandbox=\"\""))
  }
}
