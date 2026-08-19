import Testing

@testable import RobinStyling

@Suite("Typed keyframe animations")
struct KeyframeTests {
  @Test func emitsAtKeyframesWithStopsSortedByPercentage() throws {
    let animation = KeyframeAnimation(
      name: "fade-in",
      stops: [
        Keyframe(percentage: 100, declarations: [.init(.color, "black")]),
        Keyframe(percentage: 0, declarations: [.init(.color, "white")]),
      ]
    )

    let result = try TypedCSSCompiler.compile([], animations: [animation])

    #expect(result.css == "@keyframes fade-in{0%{color:white}100%{color:black}}")
  }

  @Test func multipleAnimationsAreOrderedByName() throws {
    let a = KeyframeAnimation(name: "a", stops: [Keyframe(percentage: 0, declarations: [])])
    let b = KeyframeAnimation(name: "b", stops: [Keyframe(percentage: 0, declarations: [])])

    let result = try TypedCSSCompiler.compile([], animations: [b, a])

    let aRange = try #require(result.css.range(of: "@keyframes a"))
    let bRange = try #require(result.css.range(of: "@keyframes b"))
    #expect(aRange.lowerBound < bRange.lowerBound)
  }
}
