import RobinData
import Testing

@Suite("SQLite database adapter")
struct SQLiteDatabaseTests {
  @Test func persistentStorageRequiresAnAbsolutePath() async {
    await #expect(throws: SQLiteDatabaseError.relativePath("relative.sqlite")) {
      try await SQLiteDatabase(storage: .file(path: "relative.sqlite"))
    }
  }

  @Test func repositoryTransactionsMigrationsAndHealth() async throws {
    let testDatabase = try await TestDatabase.sqlite()
    let database = testDatabase.database
    do {
      try await runDatabaseConformance(database)
      try await testDatabase.remove()
    } catch {
      try? await testDatabase.remove()
      throw error
    }
  }
}
