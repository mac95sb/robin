/// A stable, string-backed key into a theme corner-radius scale.
public struct RadiusToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the radius value in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a radius token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional small corner-radius token.
  public static let small = Self(rawValue: "small")
  /// The conventional medium corner-radius token.
  public static let medium = Self(rawValue: "medium")
}
