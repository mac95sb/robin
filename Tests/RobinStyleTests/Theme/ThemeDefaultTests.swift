import RobinStyle
import Testing

@Suite("Default theme")
struct ThemeDefaultTests {
  @Test func defaultThemeCoversTheFullNamedTokenScale() {
    let theme = Theme.default

    #expect(Set(theme.spacing.keys) == [.xs, .sm, .md, .lg, .xl, .xxl])
    #expect(Set(theme.radii.keys) == [.xs, .sm, .md, .lg, .xl, .full])
    #expect(Set(theme.shadows.keys) == [.sm, .md, .lg, .xl])
    #expect(Set(theme.breakpoints.keys) == [.sm, .md, .lg, .xl, .xxl])
  }

  @Test func defaultThemeBreakpointsMatchTheTailwindInformedScale() {
    let theme = Theme.default

    #expect(theme.breakpoints[.sm] == 640)
    #expect(theme.breakpoints[.md] == 768)
    #expect(theme.breakpoints[.lg] == 1024)
    #expect(theme.breakpoints[.xl] == 1280)
    #expect(theme.breakpoints[.xxl] == 1536)
  }

  @Test func defaultThemeScalesIncreaseMonotonically() {
    let theme = Theme.default

    let spacing = [SpacingToken.xs, .sm, .md, .lg, .xl, .xxl].map { theme.spacing[$0]! }
    let radii = [RadiusToken.xs, .sm, .md, .lg, .xl].map { theme.radii[$0]! }

    #expect(spacing == spacing.sorted())
    #expect(radii == radii.sorted())
    #expect(theme.radii[.full]! > theme.radii[.xl]!)
  }

  @Test func defaultThemeSuppliesEveryColorTokenInBothPalettes() {
    let theme = Theme.default

    let tokens: Set<ColorToken> = [.background, .foreground, .accent, .border]
    #expect(Set(theme.lightColors.keys) == tokens)
    #expect(Set(theme.darkColors.keys) == tokens)
  }
}
