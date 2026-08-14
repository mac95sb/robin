/// A stable, string-backed key into a theme shadow scale.
public struct ShadowToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the shadow value in theme dictionaries.
  public let rawValue: String

  /// Creates a shadow token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional raised-surface shadow token.
  public static let raised = Self(rawValue: "raised")
}
