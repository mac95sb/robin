import Crypto
import RobinCore

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
