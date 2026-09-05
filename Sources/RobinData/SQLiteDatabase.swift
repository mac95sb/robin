import Foundation
import NIOCore
import SQLiteNIO

/// Robin's zero-configuration SQLite database and single-connection pool.
public actor SQLiteDatabase: Database {
  /// SQLite storage selection.
  public enum Storage: Sendable {
    /// A disposable in-memory database.
    case memory
    /// A persistent database at an absolute file path.
    case file(path: String)
  }

  public nonisolated let dialect = SQLDialect.sqlite
  private let connection: SQLiteConnection
  private let gate = ConnectionGate()
  private var closed = false

  /// Opens a SQLite database.
  public init(storage: Storage = .memory) async throws {
    switch storage {
    case .memory:
      connection = try await SQLiteConnection.open(storage: .memory)
    case .file(let path):
      guard path.hasPrefix("/") else { throw SQLiteDatabaseError.relativePath(path) }
      connection = try await SQLiteConnection.open(storage: .file(path: path))
    }
    _ = try await connection.query("PRAGMA foreign_keys = ON")
  }

  public func withConnection<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result {
    try await gate.acquire()
    do {
      try Task.checkCancellation()
      try ensureOpen()
      let result = try await operation(SQLiteConnectionAdapter(connection: connection))
      await gate.release()
      return result
    } catch {
      await gate.release()
      throw error
    }
  }

  public func transaction<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result {
    try await gate.acquire()
    let adapter = SQLiteConnectionAdapter(connection: connection)
    do {
      try Task.checkCancellation()
      try ensureOpen()
      _ = try await connection.query("BEGIN IMMEDIATE")
      let result = try await operation(adapter)
      try Task.checkCancellation()
      _ = try await connection.query("COMMIT")
      await gate.release()
      return result
    } catch {
      // The future-based cleanup completes even when the calling task is cancelled.
      _ = try? await connection.query("ROLLBACK").get()
      await gate.release()
      throw error
    }
  }

  public func isHealthy() async -> Bool {
    do { try await gate.acquire() } catch { return false }
    let healthy: Bool
    if closed {
      healthy = false
    } else {
      healthy = (try? await connection.query("SELECT 1")) != nil
    }
    await gate.release()
    return healthy
  }

  public func shutdown() async throws {
    guard !closed else { return }
    closed = true
    try await gate.acquire(checkCancellation: false)
    do {
      try await connection.close().get()
      await gate.release()
    } catch {
      await gate.release()
      throw error
    }
  }

  private func ensureOpen() throws {
    if closed { throw SQLiteDatabaseError.closed }
  }
}

private actor ConnectionGate {
  private var available = true
  private var waiters: [(id: UUID, continuation: CheckedContinuation<Void, Error>)] = []

  func acquire(checkCancellation: Bool = true) async throws {
    if checkCancellation { try Task.checkCancellation() }
    guard !available else {
      available = false
      return
    }
    let id = UUID()
    if !checkCancellation {
      try await withCheckedThrowingContinuation { waiters.append((id, $0)) }
      return
    }
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { waiters.append((id, $0)) }
    } onCancel: {
      Task { await self.cancel(id) }
    }
  }

  private func cancel(_ id: UUID) {
    guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
    waiters.remove(at: index).continuation.resume(throwing: CancellationError())
  }

  func release() {
    guard !waiters.isEmpty else {
      available = true
      return
    }
    waiters.removeFirst().continuation.resume()
  }
}

private struct SQLiteConnectionAdapter: DatabaseConnection {
  let dialect = SQLDialect.sqlite
  let connection: SQLiteConnection

  func query(_ statement: SQLStatement) async throws -> [DatabaseRow] {
    let rendered = statement.render(for: dialect)
    let rows = try await connection.query(rendered.sql, rendered.bindings.map(\.sqliteData))
    return rows.map { row in
      DatabaseRow(
        Dictionary(
          row.columns.map { ($0.name, $0.data.databaseValue) },
          uniquingKeysWith: { first, _ in first }
        ))
    }
  }
}

extension DatabaseValue {
  fileprivate var sqliteData: SQLiteData {
    switch self {
    case .null: .null
    case .integer(let value): .integer(Int(value))
    case .real(let value): .float(value)
    case .text(let value): .text(value)
    case .blob(let value): .blob(ByteBuffer(bytes: value))
    case .boolean(let value): .integer(value ? 1 : 0)
    }
  }
}

extension SQLiteData {
  fileprivate var databaseValue: DatabaseValue {
    switch self {
    case .null: .null
    case .integer(let value): .integer(Int64(value))
    case .float(let value): .real(value)
    case .text(let value): .text(value)
    case .blob(let value): .blob(Data(value.readableBytesView))
    }
  }
}
