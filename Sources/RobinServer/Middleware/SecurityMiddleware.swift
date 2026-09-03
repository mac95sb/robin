import HTTPTypes
import StructuredFieldValues

extension Middleware {
  /// Enforces body, origin, CSRF, rate-limit, and baseline response-header policy.
  public static func security(_ policy: SecurityPolicy) -> Self {
    let limiter = policy.requestsPerMinute.map { RateLimiter(limit: $0) }
    let routeLimiters = policy.routeRequestsPerMinute.mapValues { RateLimiter(limit: $0) }
    return Self { request, context, next in
      guard request.body.count <= policy.maximumBodyBytes else {
        return secured(
          .text("Request body too large", status: HTTPResponse.Status(code: 413)),
          policy: policy,
          origin: request.header(.origin),
          requestID: context.requestID
        )
      }

      let origin = request.header(.origin)
      if let origin, !policy.allowedOrigins.contains(origin) {
        return secured(
          .text("Origin not allowed", status: .forbidden),
          policy: policy,
          origin: nil,
          requestID: context.requestID
        )
      }

      if request.method.rawValue.caseInsensitiveCompare("OPTIONS") == .orderedSame, origin != nil {
        var response = Response(status: HTTPResponse.Status(code: 204))
        applyHeaders(to: &response, policy: policy, origin: origin, requestID: context.requestID)
        return response
      }

      if Self.requiresCSRF(request, sessionCookieName: policy.sessionCookieName) {
        let header = request.header(Self.csrfHeader)
        guard let cookie = request.cookie(named: policy.csrfCookieName), header == cookie else {
          return secured(
            .text("CSRF validation failed", status: .forbidden),
            policy: policy,
            origin: origin,
            requestID: context.requestID
          )
        }
      }

      let client =
        context.principal?.id ?? context.sessionID ?? context.tenant?.id ?? context.clientAddress
        ?? "anonymous"
      let selectedLimiter = routeLimiters[request.path] ?? limiter
      let rateLimit = await selectedLimiter?.decision(for: "\(client):\(request.path)")
      if let rateLimit, !rateLimit.isAllowed {
        var response = secured(
          .text("Too many requests", status: HTTPResponse.Status(code: 429)),
          policy: policy,
          origin: origin,
          requestID: context.requestID
        )
        applyRateLimit(rateLimit, to: &response)
        return response
      }

      var response = try await next.respond(to: request, context: context)
      applyHeaders(to: &response, policy: policy, origin: origin, requestID: context.requestID)
      if let rateLimit { applyRateLimit(rateLimit, to: &response) }
      return response
    }
  }

  private static func requiresCSRF(_ request: Request, sessionCookieName: String) -> Bool {
    guard ["POST", "PUT", "PATCH", "DELETE"].contains(request.method.rawValue.uppercased()) else {
      return false
    }
    let contentType = request.header(.contentType)?.lowercased() ?? ""
    let isBrowserForm =
      contentType.contains("application/x-www-form-urlencoded")
      || contentType.contains("multipart/form-data")
    return isBrowserForm || request.cookie(named: sessionCookieName) != nil
  }

  private static let csrfHeader = HTTPField.Name("x-csrf-token")!
  private static let requestIDHeader = HTTPField.Name("x-request-id")!
  private static let contentSecurityPolicyHeader = HTTPField.Name("content-security-policy")!
  private static let frameOptionsHeader = HTTPField.Name("x-frame-options")!
  private static let contentTypeOptionsHeader = HTTPField.Name("x-content-type-options")!
  private static let referrerPolicyHeader = HTTPField.Name("referrer-policy")!
  private static let allowOriginHeader = HTTPField.Name("access-control-allow-origin")!
  private static let allowMethodsHeader = HTTPField.Name("access-control-allow-methods")!
  private static let allowHeadersHeader = HTTPField.Name("access-control-allow-headers")!
  private static let maxAgeHeader = HTTPField.Name("access-control-max-age")!
  private static let rateLimitLimitHeader = HTTPField.Name("ratelimit-limit")!
  private static let rateLimitRemainingHeader = HTTPField.Name("ratelimit-remaining")!
  private static let rateLimitResetHeader = HTTPField.Name("ratelimit-reset")!

  private static func secured(
    _ response: Response,
    policy: SecurityPolicy,
    origin: String?,
    requestID: String
  ) -> Response {
    var response = response
    applyHeaders(to: &response, policy: policy, origin: origin, requestID: requestID)
    return response
  }

  private static func applyHeaders(
    to response: inout Response,
    policy: SecurityPolicy,
    origin: String?,
    requestID: String
  ) {
    response.head.headerFields[requestIDHeader] = requestID
    response.head.headerFields[contentSecurityPolicyHeader] = policy.contentSecurityPolicy
    response.head.headerFields[frameOptionsHeader] = "DENY"
    response.head.headerFields[contentTypeOptionsHeader] = "nosniff"
    response.head.headerFields[referrerPolicyHeader] = "strict-origin-when-cross-origin"
    if let origin, policy.allowedOrigins.contains(origin) {
      response.head.headerFields[allowOriginHeader] = origin
      response.head.headerFields[allowMethodsHeader] =
        "GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS"
      response.head.headerFields[allowHeadersHeader] = policy.allowedRequestHeaders.joined(
        separator: ", ")
      response.head.headerFields[maxAgeHeader] = String(policy.preflightMaximumAge)
      response.head.headerFields[.vary] = "Origin"
    }
  }

  private static func applyRateLimit(_ decision: RateLimiter.Decision, to response: inout Response)
  {
    let encoder = StructuredFieldValueEncoder()
    response.head.headerFields[rateLimitLimitHeader] = encode(decision.limit, with: encoder)
    response.head.headerFields[rateLimitRemainingHeader] = encode(decision.remaining, with: encoder)
    let seconds = max(0, decision.resetsAfter.components.seconds)
    response.head.headerFields[rateLimitResetHeader] = encode(seconds, with: encoder)
  }

  private static func encode<Integer: FixedWidthInteger & Codable>(
    _ value: Integer,
    with encoder: StructuredFieldValueEncoder
  ) -> String {
    guard let bytes = try? encoder.encode(StructuredInteger(item: value)) else {
      return String(value)
    }
    return String(decoding: bytes, as: UTF8.self)
  }
}

private struct StructuredInteger<Value: FixedWidthInteger & Codable>: StructuredFieldValue {
  static var structuredFieldType: StructuredFieldType { .item }
  let item: Value
}
