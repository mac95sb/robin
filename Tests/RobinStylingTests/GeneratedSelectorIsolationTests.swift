import Testing

@testable import RobinStyling

@Suite("Generated selector isolation")
struct GeneratedSelectorIsolationTests {
  @Test func componentBaseStyleAndInstanceOverrideCompileToSeparateScopedSelectors() throws {
    let base = TypedStyle([.init(.backgroundColor, "white"), .init(.padding, "1rem")])
    let instanceOverride = TypedStyle([.init(.backgroundColor, "red")])

    let result = try TypedCSSCompiler.compile([base, instanceOverride])

    #expect(result.classNames[0] != result.classNames[1])
    #expect(result.css.components(separatedBy: "\n").count == 2)
  }
}
