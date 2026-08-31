/// A stable, string-backed key into a theme breakpoint scale.
///
/// The named members form Robin's Tailwind-informed default scale; a theme may still key its
/// breakpoint dictionary with any custom token.
public struct BreakpointToken: RawRepresentable, Hashable, Sendable {
  /// The string used to identify the breakpoint in theme dictionaries and Render IR.
  public let rawValue: String

  /// Creates a breakpoint token with a string identifier.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The small breakpoint, conventionally 640px.
  public static let sm = Self(rawValue: "sm")
  /// The medium breakpoint, conventionally 768px.
  public static let md = Self(rawValue: "md")
  /// The large breakpoint, conventionally 1024px.
  public static let lg = Self(rawValue: "lg")
  /// The extra-large breakpoint, conventionally 1280px.
  public static let xl = Self(rawValue: "xl")
  /// The extra-extra-large breakpoint, conventionally 1536px.
  public static let xxl = Self(rawValue: "xxl")
}
