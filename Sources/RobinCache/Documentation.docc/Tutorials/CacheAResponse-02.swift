import RobinCache
import RobinCore

struct PageSummary: Codable, Sendable {
  let title: String
}

let tenant = TenantScope.tenant(
  TenantContext(verified: "acme", source: .route))
let context = CacheContext(
  routeParameters: ["slug": "welcome"],
  query: ["preview": "false"],
  locale: "en-GB",
  visibility: .shared,
  tenant: tenant)
let key = try CacheKey<PageSummary>(
  namespace: "page",
  value: "welcome",
  context: context)
let cache = Cache(store: MemoryCacheStore(capacity: 500))

try await cache.store(
  PageSummary(title: "Welcome"),
  for: key,
  policy: CachePolicy(for: .minutes(5)),
  tags: [CacheTag("page:welcome")])
