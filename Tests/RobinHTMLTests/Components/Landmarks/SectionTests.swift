import RobinHTML
import Testing

@Suite("Section")
struct SectionTests {
  @Test func sectionLowersToSectionElement() throws {
    let section = try HTMLRenderer.render(Section(id: "intro") { Text { "About" } })

    #expect(section == #"<section id="intro"><p>About</p></section>"#)
  }
}
