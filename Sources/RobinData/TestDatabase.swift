/// A disposable database used by repository conformance tests.
public struct TestDatabase: Sendable {
  /// The isolated database under test.
  public let database: any Database
  private let cleanup: @Sendable () async throws -> Void

  /// Creates a test database with cleanup work.
  public init(
    database: any Database,
    cleanup: @escaping @Sendable () async throws -> Void
  ) {
    self.database = database
    self.cleanup = cleanup
  }

  /// Shuts down and removes the isolated database.
  public func remove() async throws {
    try await database.shutdown()
    try await cleanup()
  }
}

extension TestDatabase {
  /// Creates a disposable in-memory SQLite database.
  public static func sqlite() async throws -> Self {
    let database = try await SQLiteDatabase()
    return Self(database: database, cleanup: {})
  }
}
