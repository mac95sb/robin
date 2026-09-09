import RobinStyle

extension Theme {
  /// A warm, grid-led theme inspired by Swiss modernist graphic design.
  public static let modernist = Theme(
    lightColors: [
      .background: Color(lightness: 0.96, chroma: 0.01, hue: 100),
      .surface: Color(lightness: 0.99, chroma: 0.008, hue: 100),
      .surfaceHover: Color(lightness: 0.92, chroma: 0.01, hue: 100),
      .card: Color(lightness: 0.99, chroma: 0.008, hue: 100),
      .cardHover: Color(lightness: 0.92, chroma: 0.01, hue: 100),
      .foreground: Color(lightness: 0.27, chroma: 0.015, hue: 165),
      .muted: Color(lightness: 0.44, chroma: 0.015, hue: 160),
      .mutedHover: Color(lightness: 0.34, chroma: 0.015, hue: 160),
      .accent: Color(lightness: 0.42, chroma: 0.09, hue: 190),
      .accentHover: Color(lightness: 0.36, chroma: 0.09, hue: 190),
      .onAccent: Color(lightness: 0.99, chroma: 0.008, hue: 100),
      .border: Color(lightness: 0.83, chroma: 0.01, hue: 145),
    ],
    darkColors: [
      .background: Color(lightness: 0.17, chroma: 0.015, hue: 165),
      .surface: Color(lightness: 0.21, chroma: 0.015, hue: 165),
      .surfaceHover: Color(lightness: 0.26, chroma: 0.02, hue: 165),
      .card: Color(lightness: 0.26, chroma: 0.02, hue: 165),
      .cardHover: Color(lightness: 0.31, chroma: 0.02, hue: 165),
      .foreground: Color(lightness: 0.88, chroma: 0.02, hue: 165),
      .muted: Color(lightness: 0.67, chroma: 0.02, hue: 165),
      .mutedHover: Color(lightness: 0.8, chroma: 0.02, hue: 165),
      .accent: Color(lightness: 0.72, chroma: 0.1, hue: 185),
      .accentHover: Color(lightness: 0.79, chroma: 0.1, hue: 185),
      .onAccent: Color(lightness: 0.17, chroma: 0.015, hue: 165),
      .border: Color(lightness: 0.31, chroma: 0.02, hue: 165),
    ],
    identity: "modernist",
    typography: [
      .body: Typography(family: "system-ui", size: 16, weight: 400),
      .emphasis: Typography(family: "system-ui", size: 16, weight: 600),
      .heading: Typography(family: "system-ui", size: 64, weight: 700),
      .title: Typography(family: "system-ui", size: 28, weight: 600),
      .label: Typography(family: "ui-monospace", size: 13, weight: 500),
    ],
    spacing: Theme.default.spacing,
    radii: Theme.default.radii.merging([.sm: 2, .md: 3, .lg: 4, .xl: 4]) { _, value in value },
    shadows: Theme.default.shadows,
    breakpoints: Theme.default.breakpoints)
}
