/// A database-neutral result row.
public struct DatabaseRow: Equatable, Sendable {
  private let storage: [String: DatabaseValue]

  /// Creates a row from values keyed by column name.
  public init(_ values: [String: DatabaseValue]) { storage = values }

  /// Returns the value for a column name.
  public subscript(_ column: String) -> DatabaseValue? { storage[column] }

  /// All values keyed by column name.
  public var values: [String: DatabaseValue] { storage }
}
