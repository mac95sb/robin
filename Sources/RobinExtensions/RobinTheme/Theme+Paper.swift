import RobinStyle

extension Theme {
  /// A warm editorial theme for reading-focused sites and documentation.
  public static let paper = Theme(
    lightColors: [
      .background: Color(lightness: 0.975, chroma: 0.006, hue: 85),
      .surface: Color(lightness: 0.995, chroma: 0.004, hue: 85),
      .surfaceHover: Color(lightness: 0.94, chroma: 0.01, hue: 85),
      .card: Color(lightness: 0.995, chroma: 0.004, hue: 85),
      .cardHover: Color(lightness: 0.94, chroma: 0.01, hue: 85),
      .foreground: Color(lightness: 0.25, chroma: 0.015, hue: 50),
      .muted: Color(lightness: 0.48, chroma: 0.015, hue: 50),
      .mutedHover: Color(lightness: 0.36, chroma: 0.015, hue: 50),
      .accent: Color(lightness: 0.48, chroma: 0.14, hue: 35),
      .accentHover: Color(lightness: 0.4, chroma: 0.14, hue: 35),
      .onAccent: Color(lightness: 0.995, chroma: 0.004, hue: 85),
      .border: Color(lightness: 0.82, chroma: 0.012, hue: 75),
    ],
    darkColors: [
      .background: Color(lightness: 0.18, chroma: 0.012, hue: 55),
      .surface: Color(lightness: 0.22, chroma: 0.012, hue: 55),
      .surfaceHover: Color(lightness: 0.28, chroma: 0.015, hue: 55),
      .card: Color(lightness: 0.22, chroma: 0.012, hue: 55),
      .cardHover: Color(lightness: 0.28, chroma: 0.015, hue: 55),
      .foreground: Color(lightness: 0.9, chroma: 0.015, hue: 75),
      .muted: Color(lightness: 0.7, chroma: 0.02, hue: 75),
      .mutedHover: Color(lightness: 0.82, chroma: 0.02, hue: 75),
      .accent: Color(lightness: 0.7, chroma: 0.12, hue: 35),
      .accentHover: Color(lightness: 0.78, chroma: 0.1, hue: 35),
      .onAccent: Color(lightness: 0.18, chroma: 0.012, hue: 55),
      .border: Color(lightness: 0.36, chroma: 0.015, hue: 55),
    ],
    identity: "paper",
    typography: [
      .body: Typography(family: "ui-serif", size: 18, weight: 400),
      .emphasis: Typography(family: "ui-serif", size: 18, weight: 600),
      .heading: Typography(family: "system-ui", size: 56, weight: 700),
      .title: Typography(family: "system-ui", size: 28, weight: 600),
      .label: Typography(family: "system-ui", size: 13, weight: 600),
    ],
    spacing: Theme.default.spacing,
    radii: Theme.default.radii.merging([.sm: 3, .md: 4, .lg: 6, .xl: 8]) { _, value in value },
    shadows: Theme.default.shadows,
    breakpoints: Theme.default.breakpoints)
}
