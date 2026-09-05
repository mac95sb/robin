import Crypto
import Foundation
import RobinCore

/// A typed cache key whose identity includes every representation boundary.
public struct CacheKey<Value: Codable & Sendable>: Sendable {
  /// The stable provider-facing key.
  public let storageKey: String
  package let tenant: TenantScope<String>

  /// Creates a typed cache key.
  ///
  /// - Parameters:
  ///   - namespace: A logical cache namespace, such as `page` or `fragment`.
  ///   - value: The application-specific identity within the namespace.
  ///   - context: Every request value that can change the representation.
  /// - Throws: ``CacheKeyError/emptyComponent`` when the namespace or value is empty.
  public init(namespace: String, value: String, context: CacheContext) throws {
    guard !namespace.isEmpty, !value.isEmpty else { throw CacheKeyError.emptyComponent }
    tenant = context.tenant
    let identity = [
      namespace,
      String(reflecting: Value.self),
      value,
      context.routeParameters.canonical,
      context.query.canonical,
      context.locale ?? "",
      context.visibility.canonical,
      context.tenant.canonical,
    ].map { "\($0.utf8.count):\($0)" }.joined()
    let digest = SHA256.hash(data: Data(identity.utf8))
    let digits = Array("0123456789abcdef".utf8)
    storageKey = String(
      decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] },
      as: UTF8.self)
  }
}

extension Dictionary where Key == String, Value == String {
  fileprivate var canonical: String {
    sorted { $0.key < $1.key }.map {
      "\($0.key.utf8.count):\($0.key)\($0.value.utf8.count):\($0.value)"
    }
    .joined()
  }
}

extension CacheVisibility {
  fileprivate var canonical: String {
    switch self {
    case .shared: "shared"
    case .privateTo(let subject): "private:\(subject.utf8.count):\(subject)"
    }
  }
}

extension TenantScope where ID == String {
  fileprivate var canonical: String {
    switch self {
    case .none: "none"
    case .tenant(let context): "tenant:\(context.id.utf8.count):\(context.id)"
    }
  }
}
