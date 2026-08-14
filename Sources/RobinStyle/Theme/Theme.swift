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
  public init(
    lightColors: [ColorToken: Color],
    darkColors: [ColorToken: Color],
    typography: [TypographyToken: Typography],
    spacing: [SpacingToken: Int],
    radii: [RadiusToken: Int],
    shadows: [ShadowToken: Shadow] = [:],
    breakpoints: [BreakpointToken: Int]
  ) {
    self.lightColors = lightColors
    self.darkColors = darkColors
    self.typography = typography
    self.spacing = spacing
    self.radii = radii
    self.shadows = shadows
    self.breakpoints = breakpoints
  }
}
