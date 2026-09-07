/// A stable, string-backed key into a theme typography scale.
public struct TypographyToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the typography entry in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a typography token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional body-text typography token.
  public static let body = Self(rawValue: "body")
  /// The conventional heading typography token.
  public static let heading = Self(rawValue: "heading")
  /// Typography for prominent text that needs more weight than body copy.
  public static let emphasis = Self(rawValue: "emphasis")
  /// Typography for section and card titles.
  public static let title = Self(rawValue: "title")
  /// Typography for compact labels and navigation.
  public static let label = Self(rawValue: "label")
}
