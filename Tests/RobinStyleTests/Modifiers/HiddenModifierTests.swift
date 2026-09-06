@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Test func responsiveHidingPreservesTheBaseLayout() throws {
  let menu = Stack { "Navigation" }.flex().hidden(on: .below(.md))
  let styles = try StyleCompiler.compile(
    .fragment(menu.body.nodes), theme: .default, mode: .production)
  #expect(styles.css.contains("display:flex"))
  #expect(styles.css.contains("display:none"))
  #expect(styles.css.contains("max-width:767px"))
}
