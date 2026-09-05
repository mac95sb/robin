import Foundation
import RobinData
import RobinJobs
import RobinOwnershipValidation
import Testing

@Test func consumedAcknowledgementsAndAbandonedLeases() async throws {
  let database = try await SQLiteDatabase()
  do {
    let queue = try await SQLiteJobQueue(database: database)
    let now = Date()
    _ = try await queue.enqueue(
      .init(
        id: "owned", type: "test", payload: Data(), tenant: .none,
        scheduledAt: now, idempotencyKey: nil, retryPolicy: .init()))
    let first = try #require(
      try await queue.claim(tenant: .none, workerID: "first", now: now, leaseDuration: 1))
    do {
      let abandoned = OwnedJobClaim(first, queue: queue)
      _ = consume abandoned
    }
    let reclaimed = try #require(
      try await queue.claim(
        tenant: .none, workerID: "second",
        now: now.addingTimeInterval(2), leaseDuration: 1))
    #expect(reclaimed.token != first.token)
    let owned = OwnedJobClaim(reclaimed, queue: queue)
    try await owned.complete()
    let next = try await queue.claim(
      tenant: .none, workerID: "third",
      now: now.addingTimeInterval(4), leaseDuration: 1)
    #expect(next == nil)
    await queue.shutdown()
    try await database.shutdown()
  } catch {
    try? await database.shutdown()
    throw error
  }
}
