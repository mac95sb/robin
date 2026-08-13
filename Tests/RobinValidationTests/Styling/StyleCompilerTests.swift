import Testing

@testable import RobinValidation

@Suite("Deterministic typed CSS")
struct StyleCompilerTests {
  private let styles = [
    TypedStyle([
      .init(.color, " OKLCH(62% 0.2 250) "),
      .init(.padding, "1rem"),
      .init(.color, "oklch(60% 0.2 250)"),
    ]),
    TypedStyle([
      .init(.padding, "1rem"),
      .init(.color, "oklch(60% 0.2 250)"),
    ]),
    TypedStyle([.init(.display, "grid"), .init(.gap, "0.5rem")]),
  ]

  @Test func normalizesDeduplicatesOrdersAndEmitsByteStableCSS() {
    let first = TypedCSSCompiler.compile(styles)
    let second = TypedCSSCompiler.compile(styles.reversed())

    #expect(first.css == second.css)
    #expect(first.classNames[0] == first.classNames[1])
    #expect(first.css.components(separatedBy: "\n").count == 2)
    #expect(first.css.contains("color:oklch(60% 0.2 250);padding:1rem"))
  }

}
