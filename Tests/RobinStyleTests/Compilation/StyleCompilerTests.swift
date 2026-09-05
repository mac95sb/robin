@_spi(Rendering) import RobinCore
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle
import Testing

private struct TextFixture: RobinHTML.Component {
  var body: RobinHTML.ComponentContent {
    .node(.element(.init(kind: .p, children: [.text("Body")])))
  }
}

private let theme = Theme(
  lightColors: [
    .background: Color(lightness: 0.98, chroma: 0.01, hue: 250),
    .foreground: Color(lightness: 0.2, chroma: 0.02, hue: 250),
    .accent: Color(lightness: 0.62, chroma: 0.2, hue: 250),
    .border: Color(lightness: 0.8, chroma: 0.02, hue: 250),
  ],
  darkColors: [
    .background: Color(lightness: 0.15, chroma: 0.01, hue: 250),
    .foreground: Color(lightness: 0.95, chroma: 0.01, hue: 250),
    .accent: Color(lightness: 0.72, chroma: 0.18, hue: 250),
    .border: Color(lightness: 0.4, chroma: 0.02, hue: 250),
  ],
  typography: [.body: Typography(family: "System", size: 16, weight: 400)],
  spacing: [.md: 16],
  radii: [.md: 8],
  breakpoints: [.lg: 960]
)

private struct PropertyKey {
  static let color = "color"
  static let fontFamily = "font-family"
  static let padding = "padding"
}

private struct ConditionKey {
  static let dark = "dark"

  static func minimumWidth(_ token: BreakpointToken) -> String {
    "minimum-width-token:\(token.rawValue)"
  }
}

private func tokenDeclaration(
  _ property: String,
  _ token: String,
  condition: String = ""
) -> StyleDeclaration {
  .init(property: property, payload: .token(token), condition: condition)
}

@Suite("Deterministic CSS compilation")
struct StyleCompilerTests {
  @Test func resolvesTokensDeduplicatesAndIsIndependentOfTraversalOrder() throws {
    let styles = [
      tokenDeclaration(PropertyKey.color, ColorToken.foreground.rawValue),
      tokenDeclaration(PropertyKey.padding, SpacingToken.md.rawValue),
    ]
    let first = RobinHTML.RenderNode.fragment([
      .element(.init(kind: .p, styles: styles)),
      .element(.init(kind: .section, styles: Array(styles.reversed()))),
    ])
    let second = RobinHTML.RenderNode.fragment([
      .element(.init(kind: .section, styles: Array(styles.reversed()))),
      .element(.init(kind: .p, styles: styles)),
    ])

    let firstResult = try StyleCompiler.compile(first, theme: theme, mode: .production)
    let secondResult = try StyleCompiler.compile(second, theme: theme, mode: .production)

    #expect(firstResult == secondResult)
    #expect(firstResult.css.components(separatedBy: "{").count - 1 == 1)
    #expect(firstResult.css.contains("color:oklch(0.2 0.02 250);"))
    #expect(firstResult.css.contains("padding:16px;"))
  }

  @Test func completeAssignmentsAreStableWhenAliasedSignaturesChangeTraversalOrder() throws {
    let aliasTheme = Theme(
      lightColors: [
        .foreground: Color(lightness: 0.2, chroma: 0.02, hue: 250),
        .accent: Color(lightness: 0.2, chroma: 0.02, hue: 250),
      ],
      darkColors: [:],
      typography: [:],
      spacing: [:],
      radii: [:],
      breakpoints: [:]
    )
    let foreground = tokenDeclaration(PropertyKey.color, ColorToken.foreground.rawValue)
    let accent = tokenDeclaration(PropertyKey.color, ColorToken.accent.rawValue)
    let first = RobinHTML.RenderNode.fragment([
      .element(.init(kind: .p, styles: [foreground])),
      .element(.init(kind: .p, styles: [accent])),
    ])
    let second = RobinHTML.RenderNode.fragment([
      .element(.init(kind: .p, styles: [accent])),
      .element(.init(kind: .p, styles: [foreground])),
    ])

    let firstResult = try StyleCompiler.compile(first, theme: aliasTheme, mode: .production)
    let secondResult = try StyleCompiler.compile(second, theme: aliasTheme, mode: .production)

    #expect(firstResult == secondResult)
  }

  @Test func emitsReadableDevelopmentAndOrderedConditionalRules() throws {
    let styles = [
      tokenDeclaration(PropertyKey.color, ColorToken.foreground.rawValue),
      tokenDeclaration(
        PropertyKey.padding,
        SpacingToken.md.rawValue,
        condition: ConditionKey.minimumWidth(.lg)
      ),
      tokenDeclaration(
        PropertyKey.color,
        ColorToken.foreground.rawValue,
        condition: ConditionKey.dark
      ),
    ]
    let root = RobinHTML.RenderNode.element(.init(kind: .main, styles: styles))

    let result = try StyleCompiler.compile(root, theme: theme, mode: .development)

    #expect(result.css.contains("\n"))
    let base = try #require(result.css.range(of: ".r1-"))
    let responsive = try #require(result.css.range(of: "@media (min-width:960px)"))
    let mode = try #require(result.css.range(of: "@media (prefers-color-scheme:dark)"))
    #expect(base.lowerBound < responsive.lowerBound)
    #expect(responsive.lowerBound < mode.lowerBound)
  }

  @Test func ordersResponsiveRulesByNumericMinimumWidth() throws {
    let narrow = BreakpointToken(rawValue: "narrow")
    let wide = BreakpointToken(rawValue: "wide-test")
    let responsiveTheme = Theme(
      lightColors: [:],
      darkColors: [:],
      typography: [:],
      spacing: [.sm: 4, .lg: 24],
      radii: [:],
      breakpoints: [narrow: 80, wide: 960]
    )
    let root = RobinHTML.RenderNode.element(
      .init(
        kind: .main,
        styles: [
          tokenDeclaration(
            PropertyKey.padding,
            SpacingToken.lg.rawValue,
            condition: ConditionKey.minimumWidth(wide)
          ),
          tokenDeclaration(
            PropertyKey.padding,
            SpacingToken.sm.rawValue,
            condition: ConditionKey.minimumWidth(narrow)
          ),
        ]
      )
    )

    let result = try StyleCompiler.compile(root, theme: responsiveTheme, mode: .production)
    let narrowRule = try #require(result.css.range(of: "@media (min-width:80px)"))
    let wideRule = try #require(result.css.range(of: "@media (min-width:960px)"))

    #expect(narrowRule.lowerBound < wideRule.lowerBound)
  }

  @Test func typographyModifierUsesTypedWeightAndTextAlignment() throws {
    let component = TextFixture().font(.body, align: .center)
    let root = RobinHTML.RenderNode.fragment(component.body.nodes)

    let result = try StyleCompiler.compile(root, theme: theme, mode: .production)

    #expect(result.css.contains("font-weight:400;"))
    #expect(result.css.contains("text-align:center;"))
    #expect(!result.css.contains("justify-content"))
  }

  @Test func escapesCSSFontFamilyStrings() throws {
    let typography = TypographyToken(rawValue: "escaped")
    let escapedTheme = Theme(
      lightColors: [:],
      darkColors: [:],
      typography: [
        typography: Typography(family: "A\\B\"C\nD\u{0001}E</StYlE>", size: 16, weight: 400)
      ],
      spacing: [:],
      radii: [:],
      breakpoints: [:]
    )
    let root = RobinHTML.RenderNode.element(
      .init(
        kind: .p,
        styles: [tokenDeclaration(PropertyKey.fontFamily, typography.rawValue)]
      )
    )

    let result = try StyleCompiler.compile(root, theme: escapedTheme, mode: .production)

    #expect(result.css.contains(#"font-family:"A\\B\"C\A D\1 E\3C /StYlE>";"#))
    #expect(!result.css.contains("<"))
    #expect(!result.css.contains("\n"))
    #expect(!result.css.unicodeScalars.contains("\u{0001}"))
  }

  @Test func deduplicatesDifferentTokensThatResolveToIdenticalDeclarations() throws {
    let aliasTheme = Theme(
      lightColors: [
        .foreground: Color(lightness: 0.2, chroma: 0.02, hue: 250),
        .accent: Color(lightness: 0.2, chroma: 0.02, hue: 250),
      ],
      darkColors: [:],
      typography: [:],
      spacing: [:],
      radii: [:],
      breakpoints: [:]
    )
    let foreground = tokenDeclaration(PropertyKey.color, ColorToken.foreground.rawValue)
    let accent = tokenDeclaration(PropertyKey.color, ColorToken.accent.rawValue)
    let root = RobinHTML.RenderNode.fragment([
      .element(.init(kind: .p, styles: [foreground])),
      .element(.init(kind: .p, styles: [accent])),
    ])

    let result = try StyleCompiler.compile(root, theme: aliasTheme, mode: .production)

    #expect(result.css.components(separatedBy: "{").count - 1 == 1)
    #expect(result.className(for: [foreground]) == result.className(for: [accent]))
  }
}
