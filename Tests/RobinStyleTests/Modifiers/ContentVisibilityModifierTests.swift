@_spi(Rendering) import RobinCore
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle
import Testing

private struct TextFixture: RobinHTML.Component {
  var body: RobinHTML.ComponentContent {
    .node(.element(.init(kind: .p, children: [.text("Body")])))
  }
}

@Suite("Content visibility modifier")
struct ContentVisibilityModifierTests {
  @Test func contentVisibilityAutoCompilesToTheContentVisibilityProperty() throws {
    let component = TextFixture().contentVisibility(.auto)
    let root = RobinHTML.RenderNode.fragment(component.body.nodes)

    let result = try StyleCompiler.compile(root, theme: .default, mode: .production)

    #expect(result.css.contains("content-visibility:auto;"))
  }
}
