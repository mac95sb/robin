import Foundation
import RobinCore
import RobinStorage

let key = ScopedObjectKey(
  try ObjectKey("avatars/account-123.png"),
  tenant: .tenant(TenantContext(verified: "acme", source: .route)))
let imageData = Data("image bytes".utf8)
let upload = StorageWrite(
  key: key,
  contentType: "image/png",
  policy: StoragePolicy(
    contentTypes: ["image/png"],
    maximumBytes: 5_000_000),
  body: .bytes(imageData))
