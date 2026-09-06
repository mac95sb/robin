import RobinCore
import RobinHTML
import RobinStyle

extension ColorToken {
  static let surface = Self(rawValue: "surface")
  static let accentHover = Self(rawValue: "accent-hover")
  static let cardHover = Self(rawValue: "card-hover")
  static let muted = Self(rawValue: "muted")
}

extension TypographyToken {
  static let emphasis = Self(rawValue: "emphasis")
  static let title = Self(rawValue: "title")
  static let label = Self(rawValue: "label")
}

extension Theme {
  // Change the accent hue here; every page and control uses the same semantic tokens.
  static let starter = Theme(
    lightColors: [
      .background: Color(lightness: 0.99, chroma: 0.002, hue: 275),
      .surface: Color(lightness: 1, chroma: 0, hue: 275),
      .cardHover: Color(lightness: 0.97, chroma: 0.004, hue: 275),
      .foreground: Color(lightness: 0.20, chroma: 0.006, hue: 275),
      .muted: Color(lightness: 0.49, chroma: 0.008, hue: 275),
      .accentHover: Color(lightness: 0.46, chroma: 0.18, hue: 255),
      .accent: Color(lightness: 0.52, chroma: 0.18, hue: 255),
      .border: Color(lightness: 0.91, chroma: 0.004, hue: 275),
    ],
    darkColors: [
      .background: Color(lightness: 0.16, chroma: 0.008, hue: 275),
      .surface: Color(lightness: 0.19, chroma: 0.008, hue: 275),
      .cardHover: Color(lightness: 0.26, chroma: 0.008, hue: 275),
      .foreground: Color(lightness: 0.95, chroma: 0.008, hue: 275),
      .muted: Color(lightness: 0.76, chroma: 0.02, hue: 275),
      .accentHover: Color(lightness: 0.85, chroma: 0.09, hue: 255),
      .accent: Color(lightness: 0.78, chroma: 0.11, hue: 255),
      .border: Color(lightness: 0.40, chroma: 0.02, hue: 275),
    ],
    identity: "marketing-starter",
    typography: [
      .body: Typography(family: "system-ui", size: 16, weight: 400),
      .emphasis: Typography(family: "system-ui", size: 16, weight: 600),
      .heading: Typography(family: "system-ui", size: 64, weight: 650),
      .title: Typography(family: "system-ui", size: 28, weight: 600),
      .label: Typography(family: "system-ui", size: 13, weight: 500),
    ],
    spacing: Theme.default.spacing.merging([.zero: 0]) { _, value in value },
    radii: Theme.default.radii.merging([.sm: 10, .md: 14, .lg: 20, .xl: 24]) { _, value in value },
    breakpoints: Theme.default.breakpoints)
}

extension SpacingToken {
  static let zero = Self(rawValue: "zero")
}

extension Component {
  func marketingPanel() -> some Component {
    self.background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .xl)
  }

  func marketingAction(primary: Bool = true) -> some Component {
    self.flex(justify: .center, align: .center).frame(width: 160).padding(.md)
      .font(.emphasis, color: primary ? .surface : .foreground, decoration: TextDecoration.none)
      .font(.emphasis, color: primary ? .background : .foreground, on: .dark)
      .background(color: primary ? .accent : .surface)
      .background(color: primary ? .accent : .surface, on: .dark)
      .border(color: .accent, width: 0, radius: .md)
      .background(color: primary ? .accentHover : .cardHover, on: .hover || .focus)
      .background(color: primary ? .accentHover : .cardHover, on: .dark && (.hover || .focus))
  }

  func exampleCode() -> some Component {
    self.margin(.zero).padding(.lg)
      .border(color: .border, width: 0, radius: .lg)
      .frame(minWidth: 0)
  }

  func starterPage() -> some Component {
    Stack {
      self.grid(columns: 1, gap: .xxl)
        .frame(maxWidth: 1080).flexItem(grow: 1)
    }
    .flex(justify: .center)
    .padding(.lg).padding(.xxl, on: .md)
    .font(.body, color: .foreground, lineHeight: 26)
    .font(.body, color: .foreground, lineHeight: 26, on: .dark)
    .background(color: .background).background(color: .background, on: .dark)
  }

  func starterLink() -> some Component {
    self.font(.label, color: .muted, decoration: TextDecoration.none)
      .font(.label, color: .muted, on: .dark)
  }

  func marketingLink() -> some Component {
    self.starterLink()
      .font(.label, color: .accent, on: .hover || .focus)
      .font(.label, color: .accent, on: .dark && (.hover || .focus))
  }

  func starterPopover() -> some Component {
    self.popoverPosition(gap: 8).padding(.sm).frame(minWidth: 144)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
  }

  func starterMenuItem() -> some Component {
    self.flex(align: .center, gap: .sm).padding(.sm)
      .font(.label, color: .foreground, decoration: TextDecoration.none)
      .font(.label, color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, width: 0, radius: .sm)
      .font(.label, color: .accent, on: .pressed)
      .font(.label, color: .accent, on: .dark && .pressed)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }

  func starterPicker() -> some Component {
    self.flex(justify: .center, align: .center)
      .frame(width: 44, height: 44).padding(.zero)
      .font(.label, color: .foreground)
      .font(.label, color: .foreground, on: .dark)
      .background(color: .surface).background(color: .surface, on: .dark)
      .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
      .background(color: .cardHover, on: .hover || .focus)
      .background(color: .cardHover, on: .dark && (.hover || .focus))
  }

  func starterRule() -> some Component {
    self.frame(height: 1)
      .background(color: .border).background(color: .border, on: .dark)
  }

  func starterTitle() -> some Component {
    self.margin(.zero).font(.title, lineHeight: 36, letterSpacing: -1)
  }
}
