import Foundation
import RobinCache
import RobinCore
import Testing

@Suite("Tenant-safe cache")
struct CacheTests {
  @Test func isolatesTenantsAndSupportsFreshStaleAndInvalidation() async throws {
    let clock = TestClock(Date(timeIntervalSince1970: 1_000))
    let cache = Cache(store: MemoryCacheStore(capacity: 2), now: { clock.value })
    let firstTenant = TenantScope.tenant(TenantContext(verified: "first", source: .route))
    let secondTenant = TenantScope.tenant(TenantContext(verified: "second", source: .route))
    let first = try key(tenant: firstTenant)
    let second = try key(tenant: secondTenant)
    let tag = CacheTag("product:1")

    async let firstWrite: Void = cache.store(
      "first", for: first, policy: .init(for: .seconds(10), staleWhileRevalidate: .seconds(5)),
      tags: [tag])
    async let secondWrite: Void = cache.store(
      "second", for: second, policy: .init(for: .seconds(10)), tags: [tag],
    )
    _ = try await (firstWrite, secondWrite)

    #expect(try await cache.value(for: first)?.value == "first")
    #expect(try await cache.value(for: second)?.value == "second")
    clock.value.addTimeInterval(11)
    #expect(try await cache.value(for: first)?.freshness == .stale)
    #expect(try await cache.value(for: second) == nil)

    try await cache.invalidate([tag], tenant: firstTenant)
    #expect(try await cache.value(for: first) == nil)
  }

  @Test func enforcesCapacityAndHTTPValidatorPrecedence() async throws {
    let clock = TestClock(Date(timeIntervalSince1970: 1_000))
    let cache = Cache(store: MemoryCacheStore(capacity: 1), now: { clock.value })
    let context = context(tenant: .none)
    let first = try CacheKey<String>(namespace: "page", value: "one", context: context)
    let second = try CacheKey<String>(namespace: "page", value: "two", context: context)
    try await cache.store("one", for: first, policy: .init(for: .minutes(1)))
    let cached = try #require(try await cache.value(for: first))
    try await cache.store("two", for: second, policy: .init(for: .minutes(1)))

    #expect(try await cache.value(for: first) == nil)
    let validators = CacheValidators(
      entityTag: cached.entityTag, lastModified: cached.lastModified)
    #expect(validators.isNotModified(ifNoneMatch: cached.entityTag, ifModifiedSince: nil))
    #expect(
      !validators.isNotModified(
        ifNoneMatch: "\"different\"", ifModifiedSince: .distantFuture))
  }

  private func key(tenant: TenantScope<String>) throws -> CacheKey<String> {
    try CacheKey(
      namespace: "page", value: "/products/1",
      context: context(tenant: tenant))
  }

  private func context(tenant: TenantScope<String>) -> CacheContext {
    CacheContext(
      routeParameters: ["id": "1"], query: ["currency": "gbp"], locale: "en-GB",
      visibility: .privateTo("user-1"), tenant: tenant)
  }
}

private final class TestClock: @unchecked Sendable {
  var value: Date
  init(_ value: Date) { self.value = value }
}
