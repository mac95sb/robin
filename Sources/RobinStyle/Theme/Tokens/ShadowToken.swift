/// A stable, string-backed key into a theme shadow scale.
///
/// The named members form Robin's Tailwind-informed default scale; a theme may still key its
/// shadow dictionary with any custom token.
public struct ShadowToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the shadow value in theme dictionaries.
  public let rawValue: String

  /// Creates a shadow token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// A subtle, low-elevation shadow.
  public static let sm = Self(rawValue: "sm")
  /// A moderate, standard-elevation shadow.
  public static let md = Self(rawValue: "md")
  /// A pronounced, high-elevation shadow.
  public static let lg = Self(rawValue: "lg")
  /// A dramatic, maximum-elevation shadow.
  public static let xl = Self(rawValue: "xl")
}
