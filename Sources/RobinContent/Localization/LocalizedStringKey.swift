/// A strongly typed translation identifier.
public struct LocalizedStringKey: Hashable, Sendable, ExpressibleByStringLiteral {
  /// Provider-facing key.
  public let value: String

  /// Creates a nonempty translation key.
  public init(_ value: String) {
    precondition(!value.isEmpty)
    self.value = value
  }

  /// Creates a key from a string literal.
  public init(stringLiteral value: String) { self.init(value) }
}
