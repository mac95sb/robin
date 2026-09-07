import RobinCore
import RobinHTML
import RobinStyle

extension Theme {
  // Change the accent hue here; every page and control uses the same semantic tokens.
  static let starter = Theme(
    lightColors: [
      .background: Color(lightness: 0.99, chroma: 0.002, hue: 275),
      .surface: Color(lightness: 1, chroma: 0, hue: 275),
      .cardHover: Color(lightness: 0.97, chroma: 0.004, hue: 275),
      .foreground: Color(lightness: 0.20, chroma: 0.006, hue: 275),
      .muted: Color(lightness: 0.49, chroma: 0.008, hue: 275),
      .accent: Color(lightness: 0.52, chroma: 0.18, hue: 255),
      .border: Color(lightness: 0.91, chroma: 0.004, hue: 275),
    ],
    darkColors: [
      .background: Color(lightness: 0.16, chroma: 0.008, hue: 275),
      .surface: Color(lightness: 0.19, chroma: 0.008, hue: 275),
      .cardHover: Color(lightness: 0.19, chroma: 0.008, hue: 275),
      .foreground: Color(lightness: 0.95, chroma: 0.008, hue: 275),
      .muted: Color(lightness: 0.76, chroma: 0.02, hue: 275),
      .accent: Color(lightness: 0.78, chroma: 0.11, hue: 255),
      .border: Color(lightness: 0.40, chroma: 0.02, hue: 275),
    ],
    identity: "blog-starter",
    typography: [
      .body: Typography(family: "system-ui", size: 16, weight: 400),
      .heading: Typography(family: "system-ui", size: 64, weight: 650),
      .title: Typography(family: "system-ui", size: 28, weight: 600),
      .label: Typography(family: "system-ui", size: 13, weight: 500),
    ],
    spacing: Theme.default.spacing,
    radii: Theme.default.radii.merging([.sm: 10, .md: 14, .lg: 20, .xl: 24]) { _, value in value },
    breakpoints: Theme.default.breakpoints)
}
