import HTTPTypes
import RobinCore
import Testing

@testable import RobinServer

@Suite("Idempotency store")
struct IdempotencyStoreTests {
  @Test func middlewareSeparatesPrincipalsAndTenants() async throws {
    let count = Counter()
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [
        .idempotency(IdempotencyStore()),
        .init { _, context, _ in
          await count.increment()
          return .text(context.principal?.id ?? "anonymous")
        },
      ], transportCapabilities: .persistent)
    let request = Request(
      HTTPRequest(
        method: .post, scheme: "https", authority: "example.com", path: "/save",
        headerFields: [HTTPField.Name("idempotency-key")!: "same:key"]))
    for (tenant, principal) in [("a", "b:c"), ("a", "other"), ("a:b", "c")] {
      let context = RequestContext(
        requestID: "request", tenant: .init(verified: tenant, source: .route),
        principal: .init(id: principal), clientAddress: "127.0.0.1")
      for _ in 0..<2 {
        let response = await responder.respond(to: request, context: context)
        #expect(response.body.bufferedBytes == Array(principal.utf8))
      }
    }
    #expect(await count.value == 3)
  }
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
