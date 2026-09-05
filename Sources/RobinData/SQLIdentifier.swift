import Foundation

/// A safe SQL identifier.
public struct SQLIdentifier: Hashable, Sendable {
  /// The unquoted identifier.
  public let value: String

  /// Creates an identifier containing letters, digits, or underscores.
  ///
  /// The first character must be a letter or underscore.
  public init(_ value: String) throws {
    guard let first = value.unicodeScalars.first,
      first == "_" || CharacterSet.letters.contains(first),
      value.unicodeScalars.allSatisfy({ $0 == "_" || CharacterSet.alphanumerics.contains($0) })
    else { throw SQLStatementError.invalidIdentifier(value) }
    self.value = value
  }
}
