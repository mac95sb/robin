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

/// Applies pending migrations exactly once and in version order.
public struct Migrator: Sendable {
  private let database: any Database

  /// Creates a migrator for a database.
  public init(database: any Database) { self.database = database }

  /// Applies migrations that have not previously completed.
  public func migrate(_ migrations: [Migration]) async throws {
    let ordered = migrations.sorted { $0.version < $1.version }
    precondition(Set(ordered.map(\.version)).count == ordered.count)
    try await database.withConnection { connection in
      try await connection.execute(
        """
        CREATE TABLE IF NOT EXISTS robin_migrations (
          version BIGINT PRIMARY KEY,
          name TEXT NOT NULL,
          applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """)
    }
    for migration in ordered {
      try await database.transaction { connection in
        let existing = try await connection.query(
          "SELECT version FROM robin_migrations WHERE version = \(migration.version)")
        guard existing.isEmpty else { return }
        for statement in migration.statements { try await connection.execute(statement) }
        try await connection.execute(
          "INSERT INTO robin_migrations(version, name) VALUES (\(migration.version), \(migration.name))"
        )
      }
    }
  }
}
