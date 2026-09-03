import RobinCore

/// The design-token values used to resolve component styles at compilation time.
///
/// A theme is an immutable collection of independently keyed scales. Style
/// compilation performs exact token lookup and does not fall back between scales
/// or synthesize missing values.
public struct Theme: Equatable, Sendable {
  /// Colors used by declarations without a dark-mode condition.
  public let lightColors: [ColorToken: Color]

  /// Colors used by declarations under ``Condition/dark``.
  public let darkColors: [ColorToken: Color]
  /// Optional colors used by the light high-contrast palette.
  public let highContrastLightColors: [ColorToken: Color]?
  /// Optional colors used by the dark high-contrast palette.
  public let highContrastDarkColors: [ColorToken: Color]?
  /// A stable identifier for caches and generated output.
  public let identity: String

  /// Font family, size, and weight values keyed by typography token.
  public let typography: [TypographyToken: Typography]

  /// Pixel spacing values keyed by spacing token.
  public let spacing: [SpacingToken: Int]

  /// Pixel corner-radius values keyed by radius token.
  public let radii: [RadiusToken: Int]

  /// Shadow values keyed by shadow token.
  ///
  /// The compiler currently stores this scale as theme data but does not resolve
  /// it for the available public style modifiers.
  public let shadows: [ShadowToken: Shadow]

  /// Minimum viewport widths in pixels keyed by breakpoint token.
  public let breakpoints: [BreakpointToken: Int]

  /// Creates a theme from its design-token scales.
  ///
  /// - Parameters:
  ///   - lightColors: The default light color palette.
  ///   - darkColors: The dark-mode color palette.
  ///   - highContrastLightColors: An optional light high-contrast palette.
  ///   - highContrastDarkColors: An optional dark high-contrast palette.
  ///   - identity: A stable cache and output identifier.
  ///   - typography: Font values keyed by typography token.
  ///   - spacing: Pixel values keyed by spacing token.
  ///   - radii: Pixel values keyed by radius token.
  ///   - shadows: Shadow values keyed by shadow token.
  ///   - breakpoints: Minimum pixel widths keyed by breakpoint token.
  public init(
    lightColors: [ColorToken: Color],
    darkColors: [ColorToken: Color],
    highContrastLightColors: [ColorToken: Color]? = nil,
    highContrastDarkColors: [ColorToken: Color]? = nil,
    identity: String = "default",
    typography: [TypographyToken: Typography],
    spacing: [SpacingToken: Int],
    radii: [RadiusToken: Int],
    shadows: [ShadowToken: Shadow] = [:],
    breakpoints: [BreakpointToken: Int]
  ) {
    self.lightColors = lightColors
    self.darkColors = darkColors
    self.highContrastLightColors = highContrastLightColors
    self.highContrastDarkColors = highContrastDarkColors
    self.identity = identity
    self.typography = typography
    self.spacing = spacing
    self.radii = radii
    self.shadows = shadows
    self.breakpoints = breakpoints
  }
}

extension Theme {
  /// Reports palettes whose foreground and background miss a contrast threshold.
  ///
  /// - Parameter minimumRatio: The minimum accepted WCAG contrast ratio.
  /// - Returns: One diagnostic for each failing configured palette.
  public func contrastDiagnostics(minimumRatio: Double = 4.5) -> [Diagnostic] {
    let palettes: [(String, [ColorToken: Color]?)] = [
      ("light", lightColors), ("dark", darkColors),
      ("high-contrast-light", highContrastLightColors),
      ("high-contrast-dark", highContrastDarkColors),
    ]
    return palettes.compactMap { name, palette in
      guard let palette,
        let foreground = palette[.foreground],
        let background = palette[.background],
        foreground.contrastRatio(with: background) < minimumRatio
      else { return nil }
      return Diagnostic(
        .error, "Theme palette does not meet minimum contrast", context: name)
    }
  }
}

extension Theme: ApplicationTheme {}

extension Theme {
  /// Robin's default theme, implementing the full named token scale.
  public static let `default` = Theme(
    lightColors: [
      .background: Color(lightness: 0.98, chroma: 0.01, hue: 250),
      .foreground: Color(lightness: 0.2, chroma: 0.02, hue: 250),
      .accent: Color(lightness: 0.55, chroma: 0.18, hue: 250),
      .border: Color(lightness: 0.85, chroma: 0.02, hue: 250),
    ],
    darkColors: [
      .background: Color(lightness: 0.15, chroma: 0.01, hue: 250),
      .foreground: Color(lightness: 0.95, chroma: 0.01, hue: 250),
      .accent: Color(lightness: 0.7, chroma: 0.16, hue: 250),
      .border: Color(lightness: 0.35, chroma: 0.02, hue: 250),
    ],
    typography: [
      .body: Typography(family: "system-ui", size: 16, weight: 400),
      .heading: Typography(family: "system-ui", size: 32, weight: 700),
    ],
    spacing: [
      .xs: 4,
      .sm: 8,
      .md: 16,
      .lg: 24,
      .xl: 32,
      .xxl: 48,
    ],
    radii: [
      .xs: 2,
      .sm: 4,
      .md: 8,
      .lg: 12,
      .xl: 16,
      .full: 9999,
    ],
    shadows: [
      .sm: Shadow(
        color: Color(lightness: 0.15, chroma: 0.02, hue: 250, alpha: 0.08), radius: 2, y: 1),
      .md: Shadow(
        color: Color(lightness: 0.15, chroma: 0.02, hue: 250, alpha: 0.1), radius: 6, y: 3),
      .lg: Shadow(
        color: Color(lightness: 0.15, chroma: 0.02, hue: 250, alpha: 0.12), radius: 12, y: 6),
      .xl: Shadow(
        color: Color(lightness: 0.15, chroma: 0.02, hue: 250, alpha: 0.14), radius: 20, y: 10),
    ],
    breakpoints: [
      .sm: 640,
      .md: 768,
      .lg: 1024,
      .xl: 1280,
      .xxl: 1536,
    ]
  )
}
