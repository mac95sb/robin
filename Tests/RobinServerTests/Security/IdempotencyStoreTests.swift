import Testing

@testable import RobinServer

@Suite("Idempotency store")
struct IdempotencyStoreTests {
  @Test func idempotencyCoalescesConcurrentWork() async throws {
    let store = IdempotencyStore()
    let counter = Counter()
    async let first = store.response(for: "request") {
      await counter.increment()
      return .text("done")
    }
    async let second = store.response(for: "request") {
      await counter.increment()
      return .text("done")
    }

    _ = try await (first, second)
    #expect(await counter.value == 1)
  }

  private actor Counter {
    var value = 0
    func increment() { value += 1 }
  }
}
