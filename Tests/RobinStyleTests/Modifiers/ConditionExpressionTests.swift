@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Suite("Condition expressions")
struct ConditionExpressionTests {
  @Test func breakpointAndStateConditionsComposeWithoutRuntime() throws {
    let component = Text { "Adaptive" }.background(color: .accent, on: .md && (.hover || .focus))
    let compiled = try StyleCompiler.compile(
      .fragment(component.body.nodes), theme: .default, mode: .production)
    #expect(compiled.css.contains("@media (min-width:768px)"))
    #expect(compiled.css.contains(":is(:hover,:focus)"))
  }

  @Test func upperExclusiveRangesCompile() throws {
    let component = Text { "Small" }.padding(.sm, on: .between(.sm, .lg))
    let compiled = try StyleCompiler.compile(
      .fragment(component.body.nodes), theme: .default, mode: .production)
    #expect(compiled.css.contains("min-width:640px"))
    #expect(compiled.css.contains("max-width:1023px"))
  }
}
