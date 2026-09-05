/// A connection used for a bounded database operation or transaction.
public protocol DatabaseConnection: Sendable {
  /// The connection's SQL dialect.
  var dialect: SQLDialect { get }

  /// Executes a statement and returns any result rows.
  func query(_ statement: SQLStatement) async throws -> [DatabaseRow]
}

extension DatabaseConnection {
  /// Executes a statement and discards its rows.
  public func execute(_ statement: SQLStatement) async throws {
    _ = try await query(statement)
  }
}
