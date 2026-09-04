import HTTPTypes
import RobinCache
import RobinCore
import Testing

@testable import RobinServer

@Suite("Response cache middleware")
struct CacheMiddlewareTests {
  @Test func cachesPrivateTenantResponsesAndHonorsValidators() async throws {
    let cache = Cache(store: MemoryCacheStore(capacity: 10))
    let calls = CallCount()
    let tenant = TenantContext(verified: "one", source: .route)
    let context = RequestContext(
      requestID: "request", tenant: tenant, principal: .init(id: "user"))
    let middleware = Middleware.cache(
      cache,
      policy: .init(for: .minutes(1)),
      key: { request, _ in
        try ResponseCacheKey(
          value: request.path,
          context: CacheContext(
            routeParameters: [:], query: [:], locale: nil,
            visibility: .privateTo("user"), tenant: .tenant(tenant)))
      })
    let next = Middleware.Next { _, _ in
      await calls.increment()
      return .text("cached")
    }

    let first = try await middleware.respond(to: request(), context: context, next: next)
    let second = try await middleware.respond(to: request(), context: context, next: next)
    let entityTag = try #require(second.head.headerFields[.eTag])
    let conditional = try await middleware.respond(
      to: request(fields: [.ifNoneMatch: entityTag]), context: context, next: next)

    #expect(String(decoding: first.body.bufferedBytes ?? [], as: UTF8.self) == "cached")
    #expect(second.head.headerFields[.lastModified] != nil)
    #expect(conditional.head.status == .notModified)
    #expect(await calls.value == 1)
  }

  @Test func neverSharesAuthenticatedOrCrossTenantRepresentations() async throws {
    let cache = Cache(store: MemoryCacheStore(capacity: 10))
    let calls = CallCount()
    let tenant = TenantContext(verified: "one", source: .route)
    let middleware = Middleware.cache(
      cache,
      policy: .init(for: .minutes(1)),
      key: { request, _ in
        try ResponseCacheKey(
          value: request.path,
          context: CacheContext(
            routeParameters: [:], query: [:], locale: nil,
            visibility: .shared, tenant: .tenant(tenant)))
      })
    let next = Middleware.Next { _, _ in
      await calls.increment()
      return .text("private")
    }
    let authenticated = RequestContext(
      requestID: "auth", tenant: tenant, principal: .init(id: "user"))
    let otherTenant = RequestContext(
      requestID: "other", tenant: .init(verified: "two", source: .route))

    _ = try await middleware.respond(to: request(), context: authenticated, next: next)
    _ = try await middleware.respond(to: request(), context: authenticated, next: next)
    _ = try await middleware.respond(to: request(), context: otherTenant, next: next)

    #expect(await calls.value == 3)
  }

  private func request(fields: HTTPFields = [:]) -> Request {
    Request(
      HTTPRequest(
        method: .get, scheme: "https", authority: "example.com", path: "/products",
        headerFields: fields))
  }
}

private actor CallCount {
  private(set) var value = 0
  func increment() { value += 1 }
}
