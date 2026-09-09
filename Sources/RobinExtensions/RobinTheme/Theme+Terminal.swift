import RobinStyle

extension Theme {
  /// A monospace theme for developer tools and technical dashboards.
  public static let terminal = Theme(
    lightColors: [
      .background: Color(lightness: 0.96, chroma: 0.02, hue: 150),
      .surface: Color(lightness: 0.99, chroma: 0.01, hue: 150),
      .surfaceHover: Color(lightness: 0.91, chroma: 0.025, hue: 150),
      .card: Color(lightness: 0.99, chroma: 0.01, hue: 150),
      .cardHover: Color(lightness: 0.91, chroma: 0.025, hue: 150),
      .foreground: Color(lightness: 0.2, chroma: 0.03, hue: 155),
      .muted: Color(lightness: 0.45, chroma: 0.025, hue: 155),
      .mutedHover: Color(lightness: 0.32, chroma: 0.03, hue: 155),
      .accent: Color(lightness: 0.4, chroma: 0.1, hue: 150),
      .accentHover: Color(lightness: 0.34, chroma: 0.1, hue: 150),
      .onAccent: Color(lightness: 0.99, chroma: 0.01, hue: 150),
      .border: Color(lightness: 0.78, chroma: 0.03, hue: 150),
    ],
    darkColors: [
      .background: Color(lightness: 0.15, chroma: 0.025, hue: 155),
      .surface: Color(lightness: 0.19, chroma: 0.025, hue: 155),
      .surfaceHover: Color(lightness: 0.25, chroma: 0.03, hue: 155),
      .card: Color(lightness: 0.19, chroma: 0.025, hue: 155),
      .cardHover: Color(lightness: 0.25, chroma: 0.03, hue: 155),
      .foreground: Color(lightness: 0.9, chroma: 0.03, hue: 150),
      .muted: Color(lightness: 0.68, chroma: 0.04, hue: 150),
      .mutedHover: Color(lightness: 0.8, chroma: 0.04, hue: 150),
      .accent: Color(lightness: 0.75, chroma: 0.13, hue: 150),
      .accentHover: Color(lightness: 0.83, chroma: 0.1, hue: 150),
      .onAccent: Color(lightness: 0.15, chroma: 0.025, hue: 155),
      .border: Color(lightness: 0.34, chroma: 0.035, hue: 155),
    ],
    identity: "terminal",
    typography: [
      .body: Typography(family: "ui-monospace", size: 15, weight: 400),
      .emphasis: Typography(family: "ui-monospace", size: 15, weight: 600),
      .heading: Typography(family: "ui-monospace", size: 48, weight: 600),
      .title: Typography(family: "ui-monospace", size: 24, weight: 600),
      .label: Typography(family: "ui-monospace", size: 12, weight: 500),
    ],
    spacing: Theme.default.spacing,
    radii: Theme.default.radii.merging([.sm: 0, .md: 0, .lg: 0, .xl: 0]) { _, value in value },
    shadows: [:],
    breakpoints: Theme.default.breakpoints)
}
