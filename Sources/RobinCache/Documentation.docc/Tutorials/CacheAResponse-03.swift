import RobinCache
import RobinCore

let tenant = TenantScope.tenant(
  TenantContext(verified: "acme", source: .route))
let cache = Cache(store: MemoryCacheStore(capacity: 500))

try await cache.invalidate(
  [CacheTag("page:welcome")],
  tenant: tenant)
