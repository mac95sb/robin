import RobinHTML
import Testing

@Suite("Link")
struct LinkTests {
  @Test func linkLowersToAnchorWithHref() throws {
    let link = try HTMLRenderer.render(Link("/about") { "About" })

    #expect(link == #"<a href="/about">About</a>"#)
  }

  @Test func nestedTextAdaptsToPhrasingContent() throws {
    let link = try HTMLRenderer.render(Link("/about") { Text { "About" } })

    #expect(link == #"<a href="/about"><span>About</span></a>"#)
  }
}
