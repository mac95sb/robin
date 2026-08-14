@_spi(Rendering) import RobinHTML
import Testing

@Suite("Render validation")
struct RenderValidatorTests {
  @Test func validatorRejectsNestedInteractiveContent() {
    let invalid = RenderNode.element(
      .init(kind: .button, children: [.element(.init(kind: .input))])
    )

    #expect(HTMLRenderer.validate(invalid) == [.interactiveElementNestedInButton])
  }
}
