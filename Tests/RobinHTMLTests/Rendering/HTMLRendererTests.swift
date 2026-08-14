@_spi(Rendering) import RobinCore
import Testing

@_spi(Rendering) @testable import RobinHTML

@Suite("Typed component rendering")
struct HTMLRendererTests {
  @Test func lowersControlFlowEscapesValuesAndEmitsVoidElements() throws {
    let root = ComponentResolver.resolve(ExamplePage(includeInput: true))

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
    let resolver = TestStyleResolver(matchingDeclarations: nil)

    #expect(throws: RenderDiagnostic.unresolvedStyleDeclarations(element: .div)) {
      try HTMLRenderer.render(styledRoot, styles: resolver)
    }
  }

  @Test func styledElementWithMatchingClassEmitsClassName() throws {
    let resolver = TestStyleResolver(matchingDeclarations: [testStyle])

    let html = try HTMLRenderer.render(styledRoot, styles: resolver)

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

private struct TestStyleResolver: StyleClassResolving {
  let matchingDeclarations: [StyleDeclaration]?

  func className(for declarations: [StyleDeclaration]) -> String? {
    declarations == matchingDeclarations ? "r-test" : nil
  }
}

private let testStyle = StyleDeclaration(property: "display", payload: .keyword("flex"))
private let styledRoot = RenderNode.element(.init(kind: .div, styles: [testStyle]))
