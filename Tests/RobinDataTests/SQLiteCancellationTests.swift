import RobinData
import Testing

@Test(.timeLimit(.minutes(1))) func cancelledWaiterDoesNotRunAfterTheConnectionIsReleased()
  async throws
{
  let database = try await SQLiteDatabase()
  let (started, signal) = AsyncStream<Void>.makeStream()
  let (held, release) = AsyncStream<Void>.makeStream()
  let holder = Task {
    try await database.withConnection { _ in
      signal.yield(())
      for await _ in held { break }
    }
  }
  for await _ in started { break }
  let waiter = Task {
    try await database.withConnection { _ in Issue.record("A cancelled operation must not run.") }
  }
  waiter.cancel()
  await #expect(throws: CancellationError.self) { try await waiter.value }
  release.yield(())
  release.finish()
  signal.finish()
  try await holder.value
  #expect(await database.isHealthy())
  try await database.shutdown()
}
