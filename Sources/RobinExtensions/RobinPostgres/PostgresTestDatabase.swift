import Foundation
import RobinData

extension TestDatabase {
  /// Creates an isolated PostgreSQL database and removes it during cleanup.
  public static func postgres(configuration: PostgresConfiguration) async throws -> Self {
    let name =
      "robin_test_" + UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    let identifier = try SQLIdentifier(name)
    let administrator = PostgresDatabase(configuration: configuration)
    do {
      try await administrator.withConnection { connection in
        try await connection.execute("CREATE DATABASE \(identifier)")
      }
      try await administrator.shutdown()
    } catch {
      try? await administrator.shutdown()
      throw error
    }

    var testConfiguration = configuration
    testConfiguration.database = name
    let database = PostgresDatabase(configuration: testConfiguration)
    return Self(database: database) {
      let administrator = PostgresDatabase(configuration: configuration)
      do {
        try await administrator.withConnection { connection in
          try await connection.execute("DROP DATABASE \(identifier) WITH (FORCE)")
        }
        try await administrator.shutdown()
      } catch {
        try? await administrator.shutdown()
        throw error
      }
    }
  }
}
