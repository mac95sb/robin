import RobinHTML
import Testing

@Suite("Button")
struct ButtonTests {
  @Test func nestedTextAdaptsToPhrasingContent() throws {
    let button = try HTMLRenderer.render(
      Button {
        Text { "Continue" }
      }
    )

    #expect(button == #"<button type="button"><span>Continue</span></button>"#)
  }
}
