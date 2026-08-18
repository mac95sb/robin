import RobinHTML
import Testing

@Suite("ListItem")
struct ListItemTests {
  @Test func listItemLowersToLI() throws {
    let item = try HTMLRenderer.render(ListItem(id: "first") { "Entry" })

    #expect(item == #"<li id="first">Entry</li>"#)
  }
}
