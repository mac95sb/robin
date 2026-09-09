/// The supported browser-local scalar representations.
public enum StateValueKind: String, Codable, Sendable {
  /// A Boolean value.
  case boolean
  /// An integer within JavaScript's exact integer range.
  case integer
  /// A finite floating-point number.
  case number
  /// A Unicode string.
  case string
  /// A JSON value persisted as a single local state value.
  case json
}
