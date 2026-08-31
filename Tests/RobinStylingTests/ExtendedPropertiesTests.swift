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

  @Test func scrollDrivenAnimationPropertiesCompile() throws {
    let style = TypedStyle([
      .init(.scrollTimelineName, "--page-scroll"),
      .init(.viewTimelineName, "--card-view"),
      .init(.animationTimeline, "--page-scroll"),
    ])

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains("animation-timeline:--page-scroll"))
    #expect(result.css.contains("scroll-timeline-name:--page-scroll"))
    #expect(result.css.contains("view-timeline-name:--card-view"))
  }

  @Test func crossDocumentViewTransitionsCompileWithoutRuntime() throws {
    let result = try TypedCSSCompiler.compile([], viewTransitions: .enabled)

    #expect(result.css == "@view-transition{navigation:auto}")
  }
}
