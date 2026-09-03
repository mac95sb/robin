import RobinStyle
import Testing

@Suite("Color normalization")
struct ColorTests {
  @Test func normalizesNonFiniteComponentsDeterministically() {
    let color = Color(
      lightness: .nan,
      chroma: .infinity,
      hue: -.infinity,
      alpha: .nan
    )

    #expect(color.lightness == 0)
    #expect(color.chroma == 0)
    #expect(color.hue == 0)
    #expect(color.alpha == 1)
  }

  @Test func preservesExistingFiniteNormalization() {
    let color = Color(lightness: 2, chroma: -1, hue: -30, alpha: -1)

    #expect(color.lightness == 1)
    #expect(color.chroma == 0)
    #expect(color.hue == 330)
    #expect(color.alpha == 0)
  }
}
