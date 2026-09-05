import RobinHTML
import Testing

@Suite("Link")
struct LinkTests {
  @Test func rejectsExecutableURLsAndPreservesNavigation() throws {
    for value in [
      "javascript:alert(1)", " JAVASCRIPT:alert(1)", "java\tscript:alert(1)",
      "\0javascript:alert(1)", "data:text/html,test", "\\\\example.com/path",
    ] {
      #expect(throws: RenderDiagnostic.invalidURL(attribute: "href", value: value)) {
        try HTMLRenderer.render(Link(value) { "Open" })
      }
    }
    for value in [
      "/about", "../about", "?page=2", "#section", "https://example.com",
      "mailto:hello@example.com", "tel:+441234", "//example.com/path",
    ] {
      #expect(try HTMLRenderer.render(Link(value) { "Open" }).contains("Open</a>"))
    }
  }
  @Test func linkLowersToAnchorWithHref() throws {
    let link = try HTMLRenderer.render(Link("/about") { "About" })

    #expect(link == #"<a href="/about">About</a>"#)
  }

  @Test func nestedTextAdaptsToPhrasingContent() throws {
    let link = try HTMLRenderer.render(Link("/about") { Text { "About" } })

    #expect(link == #"<a href="/about"><span>About</span></a>"#)
  }
}
