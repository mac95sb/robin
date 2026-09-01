import RobinHTML
import Testing

@Suite("Strong")
struct StrongTests {
  @Test func strongLowersToStrongElement() throws {
    let strong = try HTMLRenderer.render(Strong { "critical" })

    #expect(strong == "<strong>critical</strong>")
  }
}
