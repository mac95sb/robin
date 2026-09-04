import Foundation
import HTTPTypes
import RobinServer

extension Middleware {
  /// Resolves durable RobinAuth sessions into the request principal.
  ///
  /// Invalid or expired cookies continue as anonymous requests.
  ///
  /// - Parameters:
  ///   - sessions: The durable session validator.
  ///   - store: The account store used to resolve current roles.
  ///   - cookieName: The request cookie containing the bearer token.
  public static func authSessions(
    _ sessions: AuthSessionManager,
    store: AuthStore,
    cookieName: String = "robin-session"
  ) -> Self {
    Self(requiredCapabilities: .processLocalState) { request, context, next in
      guard let token = request.cookie(named: cookieName),
        let session = try? await sessions.session(for: token),
        let account = try? await store.account(id: session.accountID)
      else { return try await next.respond(to: request, context: context) }
      let principal = AuthPrincipal(accountID: account.id, roles: account.roles).requestPrincipal
      return try await next.respond(to: request, context: context.replacing(principal: principal))
    }
  }

  /// Rejects requests whose account lacks a required permission.
  ///
  /// - Parameters:
  ///   - permission: The permission required to continue the middleware chain.
  ///   - store: The account store used to resolve current roles.
  public static func authorization(_ permission: Permission, store: AuthStore) -> Self {
    Self(requiredCapabilities: .processLocalState) { request, context, next in
      guard let id = context.principal?.id,
        let account = try? await store.account(id: id),
        AuthPrincipal(accountID: id, roles: account.roles).allows(permission)
      else { return .text("Forbidden", status: .forbidden) }
      return try await next.respond(to: request, context: context)
    }
  }
}

extension Response {
  /// Adds RobinAuth's secure, HTTP-only session cookie.
  ///
  /// - Parameters:
  ///   - token: The newly issued session token.
  ///   - name: The cookie name expected by session middleware.
  ///   - now: The time used to calculate the cookie's maximum age.
  public mutating func setAuthSessionCookie(
    _ token: SessionToken,
    name: String = "robin-session",
    now: Date = Date()
  ) {
    setSessionCookie(
      token.value, name: name, maximumAge: max(0, Int(token.expiresAt.timeIntervalSince(now))))
  }

  /// Adds a secure browser-readable cookie for double-submit CSRF validation.
  ///
  /// - Parameters:
  ///   - token: The value the browser must echo in the `X-CSRF-Token` header.
  ///   - name: The cookie name expected by RobinServer's security middleware.
  ///   - maximumAge: The nonnegative cookie lifetime in seconds.
  public mutating func setAuthCSRFCookie(
    _ token: CSRFToken,
    name: String = "robin-csrf",
    maximumAge: Int = 86_400
  ) {
    precondition(maximumAge >= 0)
    head.headerFields.append(
      HTTPField(
        name: .setCookie,
        value: "\(name)=\(token.value); Path=/; Max-Age=\(maximumAge); Secure; SameSite=Strict"))
  }
}
