@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Suite("Condition expressions")
struct ConditionExpressionTests {
  @Test func descendantSelectorsRejectSyntaxBreakouts() throws {
    for selector in ["input:checked", "> .card:hover", "#name + button:disabled"] {
      let component = Text { "Safe" }.padding(.sm, on: .has(selector) && .hover)
      let compiled = try StyleCompiler.compile(
        .fragment(component.body.nodes), theme: .default, mode: .production)
      #expect(compiled.css.contains(":has(\(selector))"))
    }
    for selector in [
      "*){}body{color:red}/*", "</style><script>bad</script>", "\\29 body", "input/*comment*/",
      "input:not(.x)",
    ] {
      let component = Text { "Reject" }.padding(.sm, on: .has(selector))
      #expect(throws: (any Error).self) {
        try StyleCompiler.compile(
          .fragment(component.body.nodes), theme: .default, mode: .production)
      }
    }
  }
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
