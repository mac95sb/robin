@_spi(Rendering) import RobinCore
import Testing

@_spi(Rendering) @testable import RobinHTML

@Suite("Typed component rendering")
struct HTMLRendererTests {
  @Test func lowersControlFlowEscapesValuesAndEmitsVoidElements() throws {
    let root = RenderNode.fragment(ExamplePage(includeInput: true).body.nodes)

    let first = try HTMLRenderer.render(root)
    let second = try HTMLRenderer.render(root)

    #expect(first == second)
    #expect(first.contains("Robin &lt;Foundation&gt;"))
    #expect(first.contains("One &amp; only"))
    #expect(first.contains("id=\"main&quot;content\""))
    #expect(first.contains("value=\"a&quot;b\""))
    #expect(first.contains("<input"))
    #expect(!first.contains("</input>"))
  }

  @Test func styledElementWithoutResolverThrows() {
    #expect(throws: RenderDiagnostic.unresolvedStyleDeclarations(element: .div)) {
      try HTMLRenderer.render(styledRoot)
    }
  }

  @Test func styledElementWithoutMatchingClassThrows() {
    #expect(throws: RenderDiagnostic.unresolvedStyleDeclarations(element: .div)) {
      try HTMLRenderer.render(styledRoot, styles: { _ in nil })
    }
  }

  @Test func styledElementWithMatchingClassEmitsClassName() throws {
    let html = try HTMLRenderer.render(styledRoot, styles: { $0 == [testStyle] ? "r-test" : nil })

    #expect(html == #"<div class="r-test"></div>"#)
  }
}

private struct ExamplePage: Component {
  let includeInput: Bool

  var body: ComponentContent {
    Stack(id: "main\"content") {
      Heading(.one) {
        "Robin <Foundation>"
      }
      for item in ["One & only", "Two"] {
        Text {
          item
        }
      }
      if includeInput {
        Input(.search, name: "query", value: "a\"b", accessibilityLabel: "Search")
      }
    }
  }
}

private let testStyle = StyleDeclaration(property: "display", payload: .keyword("flex"))
private let styledRoot = RenderNode.element(.init(kind: .div, styles: [testStyle]))
