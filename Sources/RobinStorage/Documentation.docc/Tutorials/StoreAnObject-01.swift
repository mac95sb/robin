import RobinCore
import RobinStorage

let key = ScopedObjectKey(
  try ObjectKey("avatars/account-123.png"),
  tenant: .tenant(TenantContext(verified: "acme", source: .route)))
