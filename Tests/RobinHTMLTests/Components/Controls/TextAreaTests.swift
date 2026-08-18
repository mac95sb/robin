import RobinHTML
import Testing

@Suite("TextArea")
struct TextAreaTests {
  @Test func textAreaRendersInitialValueAsTextContent() throws {
    let textArea = try HTMLRenderer.render(
      TextArea(name: "message", value: "Hello", accessibilityLabel: "Message")
    )

    #expect(textArea == #"<textarea aria-label="Message" name="message">Hello</textarea>"#)
  }

  @Test func textAreaWithoutValueRendersEmpty() throws {
    let textArea = try HTMLRenderer.render(
      TextArea(name: "message", accessibilityLabel: "Message")
    )

    #expect(textArea == #"<textarea aria-label="Message" name="message"></textarea>"#)
  }
}
