import RobinHTML
import Testing

@Suite("Emphasis")
struct EmphasisTests {
  @Test func emphasisLowersToEmElement() throws {
    let emphasis = try HTMLRenderer.render(Emphasis { "important" })

    #expect(emphasis == "<em>important</em>")
  }
}
