import RobinStyle
import Testing

@Suite("OKLCH color pipeline")
struct ColorPipelineTests {
  @Test func hexInputsNormalizeAndPreserveAlpha() throws {
    let white = try Color(hex: "#fff")
    let translucent = try Color(hex: "#33669980")
    #expect(white.lightness > 0.99)
    #expect(translucent.alpha > 0.5 && translucent.alpha < 0.51)
    #expect(throws: Color.ParseError.self) { try Color(hex: "not-a-color") }
  }

  @Test func contrastAndInterpolationUseCanonicalValues() throws {
    let black = try Color(hex: "#000")
    let white = try Color(hex: "#fff")
    #expect(black.contrastRatio(with: white) > 20)
    #expect(black.interpolated(to: white, progress: 0.5).lightness > 0.49)
  }
}
