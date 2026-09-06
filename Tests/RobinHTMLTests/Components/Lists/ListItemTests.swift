import RobinHTML
import Testing

@Suite("ListItem")
struct ListItemTests {
  @Test func listItemLowersToLI() throws {
    let item = try HTMLRenderer.render(ListItem(id: "first") { "Entry" })

    #expect(item == #"<li id="first">Entry</li>"#)
  }

  @Test func tooltipIsEscaped() throws {
    let item = try HTMLRenderer.render(ListItem(title: "Time \"UTC\" <now>") { "Entry" })
    #expect(item == "<li title=\"Time &quot;UTC&quot; &lt;now&gt;\">Entry</li>")
  }
}
