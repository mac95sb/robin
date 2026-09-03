import RobinStyle
import Testing

@Suite("Theme accessibility and data scales")
struct ThemeAccessibilityTests {
  @Test func defaultThemeMeetsTextContrast() {
    #expect(Theme.default.contrastDiagnostics().isEmpty)
  }

  @Test func dataScalesHaveExplicitOverflowAndInterpolation() throws {
    let scale = try CategoricalColorScale([.oklch(0.5, 0.1, 20)], overflow: .diagnose)
    #expect(throws: DataScaleError.self) { try scale.color(at: 1) }
    let continuous = try ContinuousColorScale([.oklch(0, 0, 0), .oklch(1, 0, 0)])
    #expect(continuous.color(at: 0.5).lightness == 0.5)
  }
}
