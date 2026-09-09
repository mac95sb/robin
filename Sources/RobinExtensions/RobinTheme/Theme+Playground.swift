import RobinStyle

extension Theme {
  /// A colorful, rounded theme for prototypes and playful products.
  public static let playground = Theme(
    lightColors: [
      .background: Color(lightness: 0.97, chroma: 0.02, hue: 310),
      .surface: Color(lightness: 1, chroma: 0, hue: 310),
      .surfaceHover: Color(lightness: 0.94, chroma: 0.03, hue: 310),
      .card: Color(lightness: 1, chroma: 0, hue: 310),
      .cardHover: Color(lightness: 0.94, chroma: 0.03, hue: 310),
      .foreground: Color(lightness: 0.25, chroma: 0.04, hue: 285),
      .muted: Color(lightness: 0.5, chroma: 0.05, hue: 285),
      .mutedHover: Color(lightness: 0.38, chroma: 0.05, hue: 285),
      .accent: Color(lightness: 0.55, chroma: 0.21, hue: 300),
      .accentHover: Color(lightness: 0.47, chroma: 0.21, hue: 300),
      .onAccent: Color(lightness: 1, chroma: 0, hue: 310),
      .border: Color(lightness: 0.84, chroma: 0.05, hue: 310),
    ],
    darkColors: [
      .background: Color(lightness: 0.16, chroma: 0.03, hue: 285),
      .surface: Color(lightness: 0.21, chroma: 0.035, hue: 285),
      .surfaceHover: Color(lightness: 0.28, chroma: 0.05, hue: 285),
      .card: Color(lightness: 0.21, chroma: 0.035, hue: 285),
      .cardHover: Color(lightness: 0.28, chroma: 0.05, hue: 285),
      .foreground: Color(lightness: 0.94, chroma: 0.025, hue: 310),
      .muted: Color(lightness: 0.72, chroma: 0.05, hue: 310),
      .mutedHover: Color(lightness: 0.85, chroma: 0.04, hue: 310),
      .accent: Color(lightness: 0.75, chroma: 0.16, hue: 300),
      .accentHover: Color(lightness: 0.83, chroma: 0.13, hue: 300),
      .onAccent: Color(lightness: 0.16, chroma: 0.03, hue: 285),
      .border: Color(lightness: 0.38, chroma: 0.06, hue: 285),
    ],
    identity: "playground",
    typography: [
      .body: Typography(family: "system-ui", size: 16, weight: 400),
      .emphasis: Typography(family: "system-ui", size: 16, weight: 700),
      .heading: Typography(family: "system-ui", size: 64, weight: 750),
      .title: Typography(family: "system-ui", size: 28, weight: 700),
      .label: Typography(family: "system-ui", size: 13, weight: 700),
    ],
    spacing: Theme.default.spacing,
    radii: Theme.default.radii.merging([.sm: 12, .md: 16, .lg: 20, .xl: 28]) { _, value in value },
    shadows: Theme.default.shadows,
    breakpoints: Theme.default.breakpoints)
}
