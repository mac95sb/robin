import Testing

@testable import RobinValidation

@Suite("Render validator")
struct RenderValidatorTests {
  @Test func representativePageIsValid() {
    let page = RepresentativePage(includeFooter: true).resolve()

    #expect(RenderValidator.validate(page).isEmpty)
  }

  @Test func invalidStructuresProduceTypedDiagnostics() {
    let invalid = RenderNode.element(
      ElementNode(
        .button,
        attributes: [RenderAttribute("id", "a"), RenderAttribute("id", "b")]
      ) {
        ElementNode(.input)
      }
    )

    #expect(
      RenderValidator.validate(invalid) == [
        .duplicateAttribute(element: .button, name: "id"),
        .interactiveElementNestedInButton,
      ]
    )
  }

  @Test func embedOriginsAreValidated() {
    let valid = RenderNode.embed(.init(source: "https://example.com/video", title: "Video"))
    #expect(RenderValidator.validate(valid).isEmpty)

    let invalid = RenderNode.embed(.init(source: "javascript:alert(1)", title: "No"))
    #expect(RenderValidator.validate(invalid) == [.invalidEmbedOrigin("javascript:alert(1)")])
  }
}
