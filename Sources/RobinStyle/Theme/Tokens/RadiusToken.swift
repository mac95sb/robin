/// A stable, string-backed key into a theme corner-radius scale.
///
/// The named members form Robin's Tailwind-informed default scale; a theme may still key its
/// radius dictionary with any custom token.
public struct RadiusToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the radius value in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a radius token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The extra-small corner radius.
  public static let xs = Self(rawValue: "xs")
  /// The small corner radius.
  public static let sm = Self(rawValue: "sm")
  /// The medium corner radius.
  public static let md = Self(rawValue: "md")
  /// The large corner radius.
  public static let lg = Self(rawValue: "lg")
  /// The extra-large corner radius.
  public static let xl = Self(rawValue: "xl")
  /// A fully rounded, pill/circle corner radius.
  public static let full = Self(rawValue: "full")
}
