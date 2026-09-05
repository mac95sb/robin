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
