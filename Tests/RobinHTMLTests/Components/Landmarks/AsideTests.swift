import RobinHTML
import Testing

@Suite("Aside")
struct AsideTests {
  @Test func asideLowersToAsideElement() throws {
    let aside = try HTMLRenderer.render(Aside(id: "sidebar") { Text { "Related" } })

    #expect(aside == #"<aside id="sidebar"><p>Related</p></aside>"#)
  }
}
