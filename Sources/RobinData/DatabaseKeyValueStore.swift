import Foundation

/// A durable key-value store backed by any Robin database adapter.
public struct DatabaseKeyValueStore: KeyValueStore {
  private let database: any Database
  private let now: @Sendable () -> Date

  /// Creates the store and its schema when needed.
  public init(database: any Database, now: @escaping @Sendable () -> Date = Date.init) async throws
  {
    self.database = database
    self.now = now
    try await database.withConnection { connection in
      let schema: SQLStatement =
        connection.dialect == .sqlite
        ? """
        CREATE TABLE IF NOT EXISTS robin_key_values (
          namespace TEXT NOT NULL,
          key TEXT NOT NULL,
          value BLOB NOT NULL,
          expires_at DOUBLE PRECISION,
          PRIMARY KEY (namespace, key)
        )
        """
        : """
        CREATE TABLE IF NOT EXISTS robin_key_values (
          namespace TEXT NOT NULL,
          key TEXT NOT NULL,
          value BYTEA NOT NULL,
          expires_at DOUBLE PRECISION,
          PRIMARY KEY (namespace, key)
        )
        """
      try await connection.execute(schema)
    }
  }

  public func put(
    _ value: Data,
    forKey key: String,
    namespace: String,
    expiresAt: Date? = nil,
    condition: KeyValueWriteCondition = .always
  ) async throws -> Bool {
    let expiration = expiresAt.map { DatabaseValue.real($0.timeIntervalSince1970) } ?? .null
    return try await database.withConnection { connection in
      let rows: [DatabaseRow]
      switch condition {
      case .always:
        rows = try await connection.query(
          """
          INSERT INTO robin_key_values(namespace, key, value, expires_at)
          VALUES (\(namespace), \(key), \(DatabaseValue.blob(value)), \(expiration))
          ON CONFLICT(namespace, key) DO UPDATE SET
            value = excluded.value, expires_at = excluded.expires_at
          RETURNING key
          """)
      case .ifAbsent:
        let timestamp = now().timeIntervalSince1970
        rows = try await connection.query(
          """
          INSERT INTO robin_key_values(namespace, key, value, expires_at)
          VALUES (\(namespace), \(key), \(DatabaseValue.blob(value)), \(expiration))
          ON CONFLICT(namespace, key) DO UPDATE SET
            value = excluded.value, expires_at = excluded.expires_at
          WHERE robin_key_values.expires_at IS NOT NULL
            AND robin_key_values.expires_at <= \(timestamp)
          RETURNING key
          """)
      case .ifPresent:
        let timestamp = now().timeIntervalSince1970
        rows = try await connection.query(
          """
          UPDATE robin_key_values SET value = \(DatabaseValue.blob(value)), expires_at = \(expiration)
          WHERE namespace = \(namespace) AND key = \(key)
            AND (expires_at IS NULL OR expires_at > \(timestamp))
          RETURNING key
          """)
      case .ifEqual(let previous):
        let timestamp = now().timeIntervalSince1970
        rows = try await connection.query(
          """
          UPDATE robin_key_values SET value = \(DatabaseValue.blob(value)), expires_at = \(expiration)
          WHERE namespace = \(namespace) AND key = \(key) AND value = \(DatabaseValue.blob(previous))
            AND (expires_at IS NULL OR expires_at > \(timestamp))
          RETURNING key
          """)
      }
      return !rows.isEmpty
    }
  }

  public func value(forKey key: String, namespace: String, at now: Date) async throws -> Data? {
    try await database.withConnection { connection in
      let rows = try await connection.query(
        """
        SELECT value FROM robin_key_values
        WHERE namespace = \(namespace) AND key = \(key)
          AND (expires_at IS NULL OR expires_at > \(now.timeIntervalSince1970))
        """)
      return rows.first?["value"]?.data
    }
  }

  public func consumeValue(forKey key: String, namespace: String, at now: Date) async throws
    -> Data?
  {
    try await database.transaction { connection in
      let rows = try await connection.query(
        """
        DELETE FROM robin_key_values
        WHERE namespace = \(namespace) AND key = \(key)
          AND (expires_at IS NULL OR expires_at > \(now.timeIntervalSince1970))
        RETURNING value
        """)
      return rows.first?["value"]?.data
    }
  }

  public func removeValue(forKey key: String, namespace: String) async throws -> Bool {
    try await database.withConnection { connection in
      !((try await connection.query(
        "DELETE FROM robin_key_values WHERE namespace = \(namespace) AND key = \(key) RETURNING key"
      )).isEmpty)
    }
  }

  public func removeExpired(at now: Date, limit: Int = 100) async throws -> Int {
    guard limit > 0 else { throw KeyValueStoreError.invalidCleanupLimit(limit) }
    return try await database.transaction { connection in
      let expired = try await connection.query(
        """
        SELECT namespace, key FROM robin_key_values
        WHERE expires_at IS NOT NULL AND expires_at <= \(now.timeIntervalSince1970)
        ORDER BY expires_at, namespace, key LIMIT \(limit)
        """)
      // ponytail: bounded row-by-row deletion stays portable; batch by adapter if cleanup throughput matters.
      for row in expired {
        guard let namespace = row["namespace"]?.string, let key = row["key"]?.string else {
          continue
        }
        try await connection.execute(
          "DELETE FROM robin_key_values WHERE namespace = \(namespace) AND key = \(key)")
      }
      return expired.count
    }
  }
}
