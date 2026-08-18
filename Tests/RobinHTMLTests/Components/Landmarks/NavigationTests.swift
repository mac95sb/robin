import RobinHTML
import Testing

@Suite("Navigation")
struct NavigationTests {
  @Test func navigationLowersToNavLandmark() throws {
    let navigation = try HTMLRenderer.render(Navigation(id: "primary") { Text { "Links" } })

    #expect(navigation == #"<nav id="primary"><p>Links</p></nav>"#)
  }
}
