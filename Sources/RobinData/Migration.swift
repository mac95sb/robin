/// A forward-only, database-neutral schema migration.
public struct Migration: Sendable {
  /// A monotonically increasing schema version.
  public let version: Int64
  /// A human-readable migration name.
  public let name: String
  /// Statements applied together in one transaction.
  public let statements: [SQLStatement]

  /// Creates a migration.
  public init(version: Int64, name: String, statements: [SQLStatement]) {
    precondition(version > 0)
    self.version = version
    self.name = name
    self.statements = statements
  }
}
