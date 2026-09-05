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
