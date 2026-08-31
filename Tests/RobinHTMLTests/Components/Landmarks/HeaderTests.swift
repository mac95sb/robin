import RobinHTML
import Testing

@Suite("Header")
struct HeaderTests {
  @Test func headerLowersToHeaderLandmark() throws {
    let header = try HTMLRenderer.render(Header(id: "top") { Text { "Welcome" } })

    #expect(header == #"<header id="top"><p>Welcome</p></header>"#)
  }
}
