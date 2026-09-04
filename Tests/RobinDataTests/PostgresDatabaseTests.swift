import Foundation
import RobinData
import RobinPostgres
import Testing

@Suite("PostgreSQL database adapter")
struct PostgresDatabaseTests {
  @Test func sharedRepositoryTransactionMigrationAndKVConformance() async throws {
    guard ProcessInfo.processInfo.environment["ROBIN_POSTGRES_TESTS"] == "1" else { return }
    let configuration = PostgresConfiguration(
      host: ProcessInfo.processInfo.environment["PGHOST"] ?? "127.0.0.1",
      port: Int(ProcessInfo.processInfo.environment["PGPORT"] ?? "5432") ?? 5432,
      username: ProcessInfo.processInfo.environment["PGUSER"] ?? "postgres",
      password: ProcessInfo.processInfo.environment["PGPASSWORD"],
      database: ProcessInfo.processInfo.environment["PGDATABASE"] ?? "postgres",
      tls: .disable
    )
    let testDatabase = try await TestDatabase.postgres(configuration: configuration)
    do {
      try await runDatabaseConformance(testDatabase.database)
      try await testDatabase.remove()
    } catch {
      try? await testDatabase.remove()
      throw error
    }
  }
}
