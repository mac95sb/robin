import Crypto
import Foundation
import RobinCore

/// An object key bound to an explicit tenant scope.
public struct ScopedObjectKey: Hashable, Sendable {
  /// The normalized object key.
  public let object: ObjectKey
  /// Stable tenant boundary encoded by storage providers.
  public let tenantIdentity: String

  /// Creates a tenant-aware object key.
  public init(_ object: ObjectKey, tenant: TenantScope<String>) {
    self.object = object
    switch tenant {
    case .none: tenantIdentity = "none"
    case .tenant(let context): tenantIdentity = "tenant:\(context.id.utf8.count):\(context.id)"
    }
  }

  package var storageIdentifier: String {
    let digest = SHA256.hash(data: Data("\(tenantIdentity):\(object.value)".utf8))
    let digits = Array("0123456789abcdef".utf8)
    return String(
      decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
      as: UTF8.self)
  }
}
