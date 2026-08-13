import SQLiteNIO

/// An in-memory SQLite key-value store with namespaces and expiration timestamps.
public actor SQLiteTTLStore {
  private let connection: SQLiteConnection

  /// Creates an empty in-memory store.
  public init() async throws {
    connection = try await SQLiteConnection.open(storage: .memory)
    _ = try await connection.query(
      """
      CREATE TABLE robin_kv (
        namespace TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        PRIMARY KEY (namespace, key)
      )
      """
    )
  }

  /// Inserts or replaces a value with an expiration timestamp.
  ///
  /// - Returns: `false` only when `onlyIfAbsent` is `true` and the key already exists.
  public func put(
    _ value: String,
    forKey key: String,
    inNamespace namespace: String,
    expiresAt: Int,
    onlyIfAbsent: Bool = false
  ) async throws -> Bool {
    if onlyIfAbsent {
      let rows = try await connection.query(
        """
        INSERT INTO robin_kv(namespace, key, value, expires_at) VALUES (?, ?, ?, ?)
        ON CONFLICT(namespace, key) DO NOTHING
        RETURNING key
        """,
        [.text(namespace), .text(key), .text(value), .integer(expiresAt)]
      )
      return !rows.isEmpty
    }

    _ = try await connection.query(
      """
      INSERT INTO robin_kv(namespace, key, value, expires_at) VALUES (?, ?, ?, ?)
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value, expires_at = excluded.expires_at
      """,
      [.text(namespace), .text(key), .text(value), .integer(expiresAt)]
    )
    return true
  }

  /// Returns an unexpired value for a key, or `nil` when absent or expired.
  public func value(
    forKey key: String,
    inNamespace namespace: String,
    at timestamp: Int
  ) async throws -> String? {
    let rows = try await connection.query(
      "SELECT value FROM robin_kv WHERE namespace = ? AND key = ? AND expires_at > ?",
      [.text(namespace), .text(key), .integer(timestamp)]
    )
    return rows.first?.column("value")?.string
  }

  @discardableResult
  public func removeExpired(at timestamp: Int, limit: Int = 100) async throws -> Int {
    let rows = try await connection.query(
      """
      DELETE FROM robin_kv
      WHERE rowid IN (SELECT rowid FROM robin_kv WHERE expires_at <= ? LIMIT ?)
      RETURNING key
      """,
      [.integer(timestamp), .integer(limit)]
    )
    return rows.count
  }

  /// Closes the underlying SQLite connection.
  public func close() async throws { try await connection.close() }
}
