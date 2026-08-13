import Testing

@testable import RobinValidation

@Suite("Component resolution and Render IR")
struct RenderIRTests {
  @Test func representativePageUsesNativeControlFlowAndIsDeterministic() {
    let page = RepresentativePage(includeFooter: true).resolve()
    let first = HTMLRenderer.render(page)
    let second = HTMLRenderer.render(page)

    #expect(first == second)
    #expect(first.components(separatedBy: "<article>").count - 1 == 48)
    #expect(first.contains("&lt;is escaped&gt;"))
    #expect(first.contains("<footer>Measured prototype</footer>"))
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

  @Test func embedIsTypedSandboxedAndOriginValidated() {
    let valid = RenderNode.embed(.init(source: "https://example.com/video", title: "Video"))
    #expect(RenderValidator.validate(valid).isEmpty)
    #expect(HTMLRenderer.render(valid).contains("sandbox=\"\""))

    let invalid = RenderNode.embed(.init(source: "javascript:alert(1)", title: "No"))
    #expect(RenderValidator.validate(invalid) == [.invalidEmbedOrigin("javascript:alert(1)")])
  }
}
