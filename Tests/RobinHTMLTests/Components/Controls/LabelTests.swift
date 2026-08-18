import RobinHTML
import Testing

@Suite("Label")
struct LabelTests {
  @Test func labelAssociatesWithTargetControl() throws {
    let label = try HTMLRenderer.render(Label(for: "email") { "Email address" })

    #expect(label == #"<label for="email">Email address</label>"#)
  }
}
