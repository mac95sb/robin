import Crypto
import Foundation
import RobinCore

/// Whether a cached representation may be shared between users.
public enum CacheVisibility: Hashable, Sendable {
  /// Content that is safe to share.
  case shared
  /// Content visible only to one authenticated subject.
  case privateTo(String)
}

/// All request state that may change a cached representation.
public struct CacheContext: Sendable {
  /// Route parameters used to produce the representation.
  public let routeParameters: [String: String]
  /// Query values selected by the route's cache policy.
  public let query: [String: String]
  /// The resolved locale, when localization is active.
  public let locale: String?
  /// The representation's authentication visibility.
  public let visibility: CacheVisibility
  /// The verified tenant scope.
  public let tenant: TenantScope<String>

  /// Creates an explicit representation context.
  public init(
    routeParameters: [String: String],
    query: [String: String],
    locale: String?,
    visibility: CacheVisibility,
    tenant: TenantScope<String>
  ) {
    self.routeParameters = routeParameters
    self.query = query
    self.locale = locale
    self.visibility = visibility
    self.tenant = tenant
  }
}

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

/// Invalid cache-key input.
public enum CacheKeyError: Error, Equatable, Sendable {
  /// A required namespace or value was empty.
  case emptyComponent
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
