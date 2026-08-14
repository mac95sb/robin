import RobinHTML
import Testing

@Suite("Stack")
struct StackTests {
  @Test func stackLowersToNeutralLayoutContainer() throws {
    let stack = try HTMLRenderer.render(
      Stack(id: "layout") {
        Text { "Body" }
      }
    )

    #expect(stack == #"<div id="layout"><p>Body</p></div>"#)
  }
}
