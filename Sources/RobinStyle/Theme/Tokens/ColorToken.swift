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
}
