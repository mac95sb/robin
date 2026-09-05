import RobinData
import RobinOwnershipValidation
import Testing

@Test func borrowedConnectionsCommitAndRollbackAcrossSuspension() async throws {
  let database = try await SQLiteDatabase()
  do {
    _ = try await ConnectionLease.withConnection(in: database) { lease in
      try await lease.query("CREATE TABLE values_for_test (value INTEGER)")
    }
    _ = try await ConnectionLease.transaction(in: database) { lease in
      await Task.yield()
      return try await lease.query("INSERT INTO values_for_test VALUES (1)")
    }
    await #expect(throws: CancellationError.self) {
      try await ConnectionLease.transaction(in: database) { lease in
        _ = try await lease.query("INSERT INTO values_for_test VALUES (2)")
        await Task.yield()
        throw CancellationError()
      }
    }
    let rows = try await ConnectionLease.withConnection(in: database) { lease in
      try await lease.query("SELECT value FROM values_for_test")
    }
    #expect(rows.count == 1)
    #expect(rows.first?["value"]?.integer == 1)
    try await database.shutdown()
  } catch {
    try? await database.shutdown()
    throw error
  }
}
