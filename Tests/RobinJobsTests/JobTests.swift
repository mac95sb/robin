import Foundation
import RobinCore
import RobinData
import RobinJobs
import Testing

@Suite("Durable jobs")
struct JobTests {
  @Test func isolatesTenantsDeduplicatesRetriesAndRecoversExpiredClaims() async throws {
    try await withQueue { queue in
      let client = JobClient(queue: queue)
      let first = TenantScope.tenant(TenantContext(verified: "first", source: .route))
      let second = TenantScope.tenant(TenantContext(verified: "second", source: .route))
      let now = Date(timeIntervalSince1970: 1_000)
      let options = JobOptions(
        scheduledAt: now, idempotencyKey: "event-1",
        retryPolicy: .init(maximumAttempts: 2, initialDelay: 1, maximumDelay: 1, jitter: 0))

      async let firstID = client.enqueue(MessageJob(text: "first"), options: options, tenant: first)
      async let duplicateID = client.enqueue(
        MessageJob(text: "duplicate"), options: options, tenant: first)
      async let secondID = client.enqueue(
        MessageJob(text: "second"), options: options, tenant: second)
      let ids = try await (firstID, duplicateID, secondID)
      #expect(ids.0 == ids.1)
      #expect(ids.0 != ids.2)
      #expect(
        try await queue.claim(tenant: second, workerID: "w", now: now, leaseDuration: 10)?.job.id
          == ids.2)

      let abandoned = try #require(
        try await queue.claim(tenant: first, workerID: "crashed", now: now, leaseDuration: 1))
      #expect(
        try await queue.claim(tenant: first, workerID: "early", now: now, leaseDuration: 1) == nil)
      let recovered = try #require(
        try await queue.claim(
          tenant: first, workerID: "recovery", now: now.addingTimeInterval(2), leaseDuration: 1))
      #expect(recovered.job.id == abandoned.job.id)
      #expect(recovered.attempt == 2)
      #expect(
        try await queue.fail(
          recovered, message: "failed", retryAt: now.addingTimeInterval(3)) == .deadLettered)
      #expect(try await queue.deadLetters(tenant: first, limit: 10).map(\.id) == [ids.0])
      #expect(try await queue.deadLetters(tenant: second, limit: 10).isEmpty)
    }
  }

  @Test func workerDecodesAndCompletesTypedJob() async throws {
    try await withQueue { queue in
      let client = JobClient(queue: queue)
      let recorder = Recorder()
      let now = Date(timeIntervalSince1970: 1_000)
      let services = ConfigurationValues().setting(TestServiceKey.self, to: "shared")
      _ = try await client.enqueue(
        MessageJob(text: "hello"), options: .init(scheduledAt: now), tenant: .none)
      let worker = JobWorker(
        queue: queue,
        handlers: [
          AnyJobHandler(MessageJob.self) { job, context in
            await recorder.record(
              "\(job.text):\(context.attempt):\(context.services[TestServiceKey.self])")
          }
        ],
        tenant: .none,
        services: services,
        now: { now },
        randomUnit: { 0 }
      )

      #expect(try await worker.runOnce())
      #expect(await recorder.values == ["hello:1:shared"])
      #expect(!(try await worker.runOnce()))
    }
  }

  private func withQueue(
    _ operation: (SQLiteJobQueue) async throws -> Void
  ) async throws {
    let database = try await TestDatabase.sqlite()
    do {
      try await operation(SQLiteJobQueue(database: database.database))
      try await database.remove()
    } catch {
      try? await database.remove()
      throw error
    }
  }
}

private struct MessageJob: Job {
  static let name = "message"
  let text: String
}

private struct TestServiceKey: ConfigurationKey {
  static let defaultValue = "default"
}

private actor Recorder {
  var values: [String] = []
  func record(_ value: String) { values.append(value) }
}
