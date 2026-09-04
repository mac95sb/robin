import Foundation
import RobinData
import Testing

func runDatabaseConformance(_ database: any Database) async throws {
  #expect(await database.isHealthy())
  let migrations = [
    Migration(
      version: 1,
      name: "create records",
      statements: [
        "CREATE TABLE records (id BIGINT PRIMARY KEY, value TEXT NOT NULL)"
      ]
    )
  ]
  try await Migrator(database: database).migrate(migrations)
  try await Migrator(database: database).migrate(migrations)

  let repository = RecordRepository(context: RepositoryContext(database: database))
  try await repository.insert(Record(id: 1, value: "kept"))
  await #expect(throws: (any Error).self) {
    try await database.transaction { connection in
      try await connection.execute("INSERT INTO records(id, value) VALUES (\(2), \("lost"))")
      throw DatabaseContractError.rollback
    }
  }

  #expect(try await repository.all() == [Record(id: 1, value: "kept")])

  let now = Date(timeIntervalSince1970: 100)
  let store = try await DatabaseKeyValueStore(database: database, now: { now })
  #expect(try await store.put(Data("one".utf8), forKey: "key", namespace: "a"))
  #expect(try await store.put(Data("two".utf8), forKey: "key", namespace: "b"))
  #expect(try await store.value(forKey: "key", namespace: "a", at: now) == Data("one".utf8))
  #expect(
    try await store.consumeValue(forKey: "key", namespace: "a", at: now) == Data("one".utf8))
  #expect(try await store.consumeValue(forKey: "key", namespace: "a", at: now) == nil)

  let winners = try await withThrowingTaskGroup(of: Bool.self) { group in
    for index in 0..<20 {
      group.addTask {
        try await store.put(
          Data("\(index)".utf8),
          forKey: "winner",
          namespace: "race",
          condition: .ifAbsent
        )
      }
    }
    var results: [Bool] = []
    for try await result in group { results.append(result) }
    return results
  }
  #expect(winners.filter(\.self).count == 1)

  #expect(
    try await store.put(
      Data("old".utf8),
      forKey: "expired",
      namespace: "a",
      expiresAt: now
    ))
  #expect(try await store.value(forKey: "expired", namespace: "a", at: now) == nil)
  #expect(
    try await store.put(
      Data("replacement".utf8),
      forKey: "expired",
      namespace: "a",
      condition: .ifAbsent
    ))
  #expect(
    try await store.value(forKey: "expired", namespace: "a", at: now) == Data("replacement".utf8))
  #expect(
    try await store.put(
      Data("old".utf8),
      forKey: "cleanup",
      namespace: "a",
      expiresAt: now
    ))
  #expect(try await store.removeExpired(at: now, limit: 1) == 1)
  await #expect(throws: KeyValueStoreError.invalidCleanupLimit(0)) {
    try await store.removeExpired(at: now, limit: 0)
  }
}

enum DatabaseContractError: Error { case rollback }

private struct Record: Codable, Equatable, Sendable {
  let id: Int64
  let value: String
}

private struct RecordRepository: Repository {
  typealias Model = Record
  let context: RepositoryContext

  func insert(_ record: Record) async throws {
    try await context.database.transaction { connection in
      try await connection.execute(
        "INSERT INTO records(id, value) VALUES (\(record.id), \(record.value))")
    }
  }

  func all() async throws -> [Record] {
    let query = DatabaseQuery<Record>("SELECT id, value FROM records ORDER BY id") { row in
      Record(id: try #require(row["id"]?.integer), value: try #require(row["value"]?.string))
    }
    return try await context.database.withConnection { try await $0.fetch(query) }
  }
}
