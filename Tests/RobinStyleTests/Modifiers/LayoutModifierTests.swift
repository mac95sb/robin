@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Suite("Typed layout modifiers")
struct LayoutModifierTests {
  @Test func flexGridAndBoxLayoutCompileWithoutRawCSS() throws {
    let component = Stack {
      Text { "One" }.flexItem(order: 2, grow: 1)
      Text { "Two" }
    }
    .flex(direction: .column, justify: .spaceBetween, align: .center, gap: .md)
    .frame(minWidth: 240, maxWidth: 960)
    .aspectRatio(16, 9)
    let node = RenderNode.fragment(component.body.nodes)
    let compiled = try StyleCompiler.compile(node, theme: .default, mode: .production)
    #expect(compiled.css.contains("display:flex"))
    #expect(compiled.css.contains("flex-direction:column"))
    #expect(compiled.css.contains("min-width:240px"))
    #expect(compiled.css.contains("aspect-ratio:16 / 9"))
  }
}
