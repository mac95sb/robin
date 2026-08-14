/// A stable, string-backed key into a theme breakpoint scale.
public struct BreakpointToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the breakpoint in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a breakpoint token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The conventional compact-layout breakpoint token.
  public static let compact = Self(rawValue: "compact")
  /// The conventional wide-layout breakpoint token.
  public static let wide = Self(rawValue: "wide")
}
