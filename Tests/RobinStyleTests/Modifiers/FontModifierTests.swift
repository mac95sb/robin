@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Test func typographySpacingPreservesNegativeTrackingAndResponsiveLeading() throws {
  let heading = Heading { "A quieter web" }
    .font(.heading, lineHeight: 40, letterSpacing: -1)
    .font(.heading, lineHeight: 64, letterSpacing: -2, on: .md)
  let styles = try StyleCompiler.compile(
    .fragment(heading.body.nodes), theme: .default, mode: .production)
  #expect(styles.css.contains("letter-spacing:-1px"))
  #expect(styles.css.contains("letter-spacing:-2px"))
  #expect(styles.css.contains("line-height:40px"))
  #expect(styles.css.contains("line-height:64px"))
  #expect(styles.css.contains("768px"))
}

@Test func linkDecorationSupportsPlainLinksAndHoverUnderlines() throws {
  let link = Link("/posts/example") { "Example" }
    .font(.body, decoration: TextDecoration.none)
    .font(.body, decoration: .underline, on: .hover)
  let styles = try StyleCompiler.compile(
    .fragment(link.body.nodes), theme: .default, mode: .production)
  #expect(styles.css.contains("text-decoration:none"))
  #expect(styles.css.contains(":hover"))
  #expect(styles.css.contains("text-decoration:underline"))
}
