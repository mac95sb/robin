/// A stable, string-backed key into a theme spacing scale.
///
/// The named members form Robin's Tailwind-informed default scale; a theme may still key its
/// spacing dictionary with any custom token.
public struct SpacingToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the spacing value in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a spacing token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The extra-small spacing step.
  public static let xs = Self(rawValue: "xs")
  /// The small spacing step.
  public static let sm = Self(rawValue: "sm")
  /// The medium spacing step.
  public static let md = Self(rawValue: "md")
  /// The large spacing step.
  public static let lg = Self(rawValue: "lg")
  /// The extra-large spacing step.
  public static let xl = Self(rawValue: "xl")
  /// The extra-extra-large spacing step.
  public static let xxl = Self(rawValue: "xxl")
}
