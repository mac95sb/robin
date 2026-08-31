import RobinHTML
import Testing

@Suite("List")
struct ListTests {
  @Test func unorderedListLowersToULByDefault() throws {
    let list = try HTMLRenderer.render(
      List { ListItem { "One" } }
    )

    #expect(list == "<ul><li>One</li></ul>")
  }

  @Test func orderedListLowersToOL() throws {
    let list = try HTMLRenderer.render(
      List(ordered: true) { ListItem { "One" } }
    )

    #expect(list == "<ol><li>One</li></ol>")
  }
}
