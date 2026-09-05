import RobinData

/// A validation-only, borrowed connection that cannot escape its database operation as a result.
public struct ConnectionLease: ~Copyable {
  private let connection: any DatabaseConnection

  private init(_ connection: any DatabaseConnection) { self.connection = connection }

  /// Executes a statement while the enclosing operation owns the connection.
  public borrowing func query(_ statement: SQLStatement) async throws -> [DatabaseRow] {
    try await connection.query(statement)
  }

  /// Borrows a connection until the asynchronous operation returns or throws.
  public static func withConnection<Result: Sendable>(
    in database: some Database,
    _ operation: @Sendable (borrowing ConnectionLease) async throws -> Result
  ) async throws -> Result {
    try await database.withConnection { connection in
      try await operation(ConnectionLease(connection))
    }
  }

  /// Borrows a transaction connection; the database commits on return and rolls back on error.
  public static func transaction<Result: Sendable>(
    in database: some Database,
    _ operation: @Sendable (borrowing ConnectionLease) async throws -> Result
  ) async throws -> Result {
    try await database.transaction { connection in
      try await operation(ConnectionLease(connection))
    }
  }
}
