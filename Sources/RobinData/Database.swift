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

/// A lifecycle-managed database or connection pool.
public protocol Database: Sendable {
  /// The database's SQL dialect.
  var dialect: SQLDialect { get }

  /// Leases a connection for one operation.
  func withConnection<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result

  /// Runs an operation atomically.
  func transaction<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result

  /// Returns whether the database can execute a trivial query.
  func isHealthy() async -> Bool

  /// Stops the pool and releases its connections.
  func shutdown() async throws
}
