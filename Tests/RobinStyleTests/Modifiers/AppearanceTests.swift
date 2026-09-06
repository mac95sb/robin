@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Test func appearanceOverridesIncludeSystemFallbackAndCompoundDarkPalette() throws {
  let simple = Stack {}.background(color: .background, on: .dark)
  let compound = Stack {}.background(color: .background, on: .dark && .hover)
  let simpleCSS = try StyleCompiler.compile(
    .fragment(simple.body.nodes), theme: .default, mode: .production
  ).css
  let compoundCSS = try StyleCompiler.compile(
    .fragment(compound.body.nodes), theme: .default, mode: .production
  ).css
  #expect(simpleCSS.contains(":root:not([data-robin-appearance])"))
  #expect(simpleCSS.contains(":root[data-robin-appearance=light]"))
  #expect(simpleCSS.contains(":root[data-robin-appearance=dark]"))
  #expect(simpleCSS.contains("prefers-color-scheme:dark"))
  let declaration = try #require(
    simpleCSS.components(separatedBy: "background-color:").dropFirst().first?.components(
      separatedBy: ";"
    ).first)
  #expect(compoundCSS.contains("background-color:\(declaration);"))
  #expect(compoundCSS.contains(":hover"))
  for css in [simpleCSS, compoundCSS] {
    #expect(!css.contains("width < 0px"))
    #expect(!css.contains("min-width:0px"))
    #expect(!css.contains(":where(:root[data-robin-appearance=light])"))
  }
}

@Test func appearanceConditionsKeepOnlyNecessaryMediaQueries() throws {
  func css(_ condition: Condition) throws -> String {
    let component = Stack {}.background(color: .background, on: condition)
    return try StyleCompiler.compile(
      .fragment(component.body.nodes), theme: .default, mode: .production
    ).css
  }
  let darkScope = ":where(:root[data-robin-appearance=dark])"
  let lightScope = ":where(:root[data-robin-appearance=light])"
  #expect(try css(.dark && .md).contains("@media (min-width:768px){\(darkScope)"))
  #expect(try css(.dark || .md).contains("@media (min-width:768px){\(lightScope)"))
  #expect(try !css(.dark || .md).contains("@media (min-width:768px){\(darkScope)"))
  #expect(try css(!.dark).contains(lightScope))
  #expect(try !css(!.dark).contains(darkScope))
  #expect(try css(.md).contains("@media (min-width:768px){.r1-"))
  #expect(try !css(.always).contains("@media (min-width:"))
}

@Test func documentCanvasUsesTheThemeInEveryAppearance() throws {
  let styles = try StyleCompiler.compile(
    .fragment(Stack {}.body.nodes), theme: .default, mode: .production)
  #expect(styles.css.contains(":root{background:oklch("))
  #expect(styles.css.contains(":root:not([data-robin-appearance]){background:oklch("))
  #expect(styles.css.contains(":root[data-robin-appearance=dark]{background:oklch("))
}
