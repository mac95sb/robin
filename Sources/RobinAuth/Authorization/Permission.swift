/// One stable authorization capability.
public struct Permission: Codable, Hashable, Sendable, ExpressibleByStringLiteral {
  /// The application-defined permission name.
  public let name: String

  /// Creates a permission.
  public init(_ name: String) {
    precondition(Self.isValid(name))
    self.name = name
  }

  /// Creates a permission from a string literal.
  public init(stringLiteral value: String) { self.init(value) }

  private static func isValid(_ value: String) -> Bool {
    !value.isEmpty && value.allSatisfy { $0.isLetter || $0.isNumber || ".:_-".contains($0) }
  }
}
