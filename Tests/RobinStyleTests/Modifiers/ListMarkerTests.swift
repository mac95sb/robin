@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle
import Testing

@Test func unmarkedListsRetainTheirSemanticsAndInheritedMarkerStyle() throws {
  let list = List { ListItem { "Message" } }.listMarker(.none)
  let root = RenderNode.fragment(list.body.nodes)
  let styles = try StyleCompiler.compile(root, theme: .default, mode: .production)
  #expect(styles.css.contains("list-style-type:none"))
  #expect(try HTMLRenderer.render(root, styles: styles.className(for:)).contains("role=\"list\""))
}
