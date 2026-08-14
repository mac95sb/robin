/// A stable, string-backed key into a theme spacing scale.
public struct SpacingToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the spacing value in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a spacing token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional small spacing token.
  public static let small = Self(rawValue: "small")
  /// The conventional medium spacing token.
  public static let medium = Self(rawValue: "medium")
  /// The conventional large spacing token.
  public static let large = Self(rawValue: "large")
}
