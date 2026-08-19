import Testing

@testable import RobinStyling

@Suite("Extended CSS surface")
struct ExtendedPropertiesTests {
  @Test func contentVisibilityAutoCompiles() throws {
    let style = TypedStyle([.init(.contentVisibility, "auto")])

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains("content-visibility:auto"))
  }

  @Test func transitionBehaviorAllowsDiscreteTransitionsUnderStartingStyle() throws {
    let discreteTransition = TypedStyle([.init(.transitionBehavior, "allow-discrete")])
    let startingStyle = TypedStyle(
      [.init(.contentVisibility, "auto")],
      condition: .startingStyle
    )

    let result = try TypedCSSCompiler.compile([discreteTransition, startingStyle])

    #expect(result.css.contains("transition-behavior:allow-discrete"))
    #expect(result.css.contains("@starting-style{"))
  }

  @Test func anchorPositioningPropertiesCompile() throws {
    let anchor = TypedStyle([.init(.anchorName, "--card-anchor")])
    let positioned = TypedStyle([.init(.positionAnchor, "--card-anchor")])

    let result = try TypedCSSCompiler.compile([anchor, positioned])

    #expect(result.css.contains("anchor-name:--card-anchor"))
    #expect(result.css.contains("position-anchor:--card-anchor"))
  }
}
