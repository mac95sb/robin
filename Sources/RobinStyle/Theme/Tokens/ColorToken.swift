/// A stable, string-backed key into a theme color palette.
public struct ColorToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the color in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a color token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional page or component background color token.
  public static let background = Self(rawValue: "background")
  /// The conventional foreground content color token.
  public static let foreground = Self(rawValue: "foreground")
  /// The conventional accent color token.
  public static let accent = Self(rawValue: "accent")
  /// The conventional border color token.
  public static let border = Self(rawValue: "border")
  /// The elevated surface color token.
  public static let surface = Self(rawValue: "surface")
  /// The hover color for an elevated surface.
  public static let surfaceHover = Self(rawValue: "surface-hover")
  /// The card background color token.
  public static let card = Self(rawValue: "card")
  /// The hover color for a card.
  public static let cardHover = Self(rawValue: "card-hover")
  /// The subdued text or surface color token.
  public static let muted = Self(rawValue: "muted")
  /// The hover color for subdued content.
  public static let mutedHover = Self(rawValue: "muted-hover")
  /// The hover color for an accent action.
  public static let accentHover = Self(rawValue: "accent-hover")
  /// The foreground color placed on an accent surface.
  public static let onAccent = Self(rawValue: "on-accent")
}
