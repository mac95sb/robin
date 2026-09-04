import RobinCache
import RobinCore

let tenant = TenantScope.tenant(
  TenantContext(verified: "acme", source: .route))
let context = CacheContext(
  routeParameters: ["slug": "welcome"],
  query: ["preview": "false"],
  locale: "en-GB",
  visibility: .shared,
  tenant: tenant)
