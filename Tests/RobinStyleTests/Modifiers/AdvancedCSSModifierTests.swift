@_spi(Rendering) import RobinHTML
import RobinStyle
import Testing

@Suite("Advanced CSS modifiers")
struct AdvancedCSSModifierTests {
  @Test func containerConditionsRequireAndUseTypedContainment() throws {
    let valid = Stack {
      Text { "Responsive" }.padding(.md, on: .containerMinimumWidth(.md))
    }.containerType(.inlineSize)
    let compiled = try StyleCompiler.compile(
      .fragment(valid.body.nodes), theme: .default, mode: .production)

    #expect(compiled.css.contains("container-type:inline-size"))
    #expect(compiled.css.contains("@container (min-width:768px)"))

    let invalid = Text { "Orphan" }.padding(.md, on: .containerMinimumWidth(.md))
    #expect(throws: ThemeError.missingContainmentAncestor) {
      try StyleCompiler.compile(
        .fragment(invalid.body.nodes), theme: .default, mode: .production)
    }
  }

  @Test func keyframesAnchorsDiscreteTransitionsAndViewTransitionsCompile() throws {
    let anchor = try Anchor("card")
    let timeline = try AnimationTimeline("cards")
    let animation = try KeyframeAnimation(stops: [
      try .init(100, opacity: 1, transform: .translate(x: 0, y: 0)),
      try .init(0, opacity: 0, transform: .translate(x: 0, y: 8)),
    ])
    let component = Stack {
      Text { "Target" }
        .position(at: anchor)
        .anchoredTop(to: anchor)
        .animation(animation, durationMilliseconds: 180)
        .animationTimeline(timeline)
        .transitionBehavior(.allowDiscrete)
        .background(color: .background, on: .startingStyle)
    }.anchor(anchor).scrollTimeline(timeline)

    let compiled = try StyleCompiler.compile(
      .fragment(component.body.nodes),
      theme: .default,
      mode: .production,
      animations: [animation],
      viewTransitions: .enabled
    )

    #expect(compiled.css.contains("anchor-name:--r-card"))
    #expect(compiled.css.contains("position-anchor:--r-card"))
    #expect(compiled.css.contains("top:anchor(--r-card bottom)"))
    #expect(compiled.css.contains("animation-timeline:--r-cards"))
    #expect(compiled.css.contains("scroll-timeline-name:--r-cards"))
    #expect(compiled.css.contains("transition-behavior:allow-discrete"))
    #expect(compiled.css.contains("@starting-style{"))
    #expect(compiled.css.contains("@keyframes \(animation.name){0%"))
    #expect(compiled.css.contains("@view-transition{navigation:auto}"))
  }

  @Test func generatedSelectorsCarryAnExplicitVersion() throws {
    let component = Text { "Versioned" }.padding(.sm)
    let compiled = try StyleCompiler.compile(
      .fragment(component.body.nodes), theme: .default, mode: .production)
    #expect(compiled.css.hasPrefix(".r1-"))
  }
}
