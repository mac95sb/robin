/// Core HTTP security controls applied before application handlers run.
public struct SecurityPolicy: Sendable {
  /// Origins allowed to make cross-origin requests.
  public let allowedOrigins: Set<String>
  /// The maximum accepted request-body size.
  public let maximumBodyBytes: Int
  /// The Content-Security-Policy value added to responses.
  public let contentSecurityPolicy: String
  /// The cookie containing the CSRF token.
  public let csrfCookieName: String
  /// The cookie that identifies session-backed requests.
  public let sessionCookieName: String
  /// Request header fields allowed by CORS preflight responses.
  public let allowedRequestHeaders: [String]
  /// Seconds browsers may cache a CORS preflight response.
  public let preflightMaximumAge: Int
  /// The optional per-client, per-path request limit.
  public let requestsPerMinute: Int?
  /// Exact-path limits that override `requestsPerMinute`.
  public let routeRequestsPerMinute: [String: Int]

  /// Creates the baseline HTTP security policy.
  ///
  /// Limits must be positive; `maximumBodyBytes` may be zero.
  public init(
    allowedOrigins: Set<String> = [],
    maximumBodyBytes: Int = 1_048_576,
    contentSecurityPolicy: String = "default-src 'self'; frame-ancestors 'none'",
    csrfCookieName: String = "robin-csrf",
    sessionCookieName: String = "robin-session",
    allowedRequestHeaders: [String] = ["Content-Type", "X-CSRF-Token"],
    preflightMaximumAge: Int = 600,
    requestsPerMinute: Int? = nil,
    routeRequestsPerMinute: [String: Int] = [:]
  ) {
    precondition(maximumBodyBytes >= 0)
    precondition(preflightMaximumAge >= 0)
    precondition(requestsPerMinute.map { $0 > 0 } ?? true)
    precondition(routeRequestsPerMinute.values.allSatisfy { $0 > 0 })
    self.allowedOrigins = allowedOrigins
    self.maximumBodyBytes = maximumBodyBytes
    self.contentSecurityPolicy = contentSecurityPolicy
    self.csrfCookieName = csrfCookieName
    self.sessionCookieName = sessionCookieName
    self.allowedRequestHeaders = allowedRequestHeaders
    self.preflightMaximumAge = preflightMaximumAge
    self.requestsPerMinute = requestsPerMinute
    self.routeRequestsPerMinute = routeRequestsPerMinute
  }
}
