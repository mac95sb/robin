/// Inputs used to choose one configured locale.
public struct LocalePreference: Sendable {
  /// Locale encoded in the matched route.
  public let route: String?
  /// Locale read from an explicit user preference cookie.
  public let user: String?
  /// Raw `Accept-Language` request header.
  public let acceptLanguage: String?

  /// Creates locale preference inputs in precedence order.
  public init(route: String? = nil, user: String? = nil, acceptLanguage: String? = nil) {
    self.route = route
    self.user = user
    self.acceptLanguage = acceptLanguage
  }
}
