import HTTPTypes

extension Middleware {
  /// Resolves a valid session cookie into the read-only request context.
  public static func session<Value>(
    _ store: SessionStore<Value>,
    cookieName: String = "robin-session"
  ) -> Self where Value: Sendable {
    Self(requiredCapabilities: .processLocalState) { request, context, next in
      guard let token = request.cookie(named: cookieName), await store.value(for: token) != nil
      else {
        return try await next.respond(to: request, context: context)
      }
      let sessionContext = context.replacing(sessionID: token)
      return try await next.respond(to: request, context: sessionContext)
    }
  }
}

extension Response {
  /// Adds a secure, HTTP-only session cookie to the response.
  public mutating func setSessionCookie(
    _ token: String,
    name: String = "robin-session",
    maximumAge: Int = 86_400
  ) {
    precondition(maximumAge >= 0)
    precondition(Self.isSafeCookieComponent(name) && Self.isSafeCookieComponent(token))
    head.headerFields.append(
      HTTPField(
        name: .setCookie,
        value: "\(name)=\(token); Path=/; Max-Age=\(maximumAge); Secure; HttpOnly; SameSite=Lax"))
  }

  /// Expires the named session cookie immediately.
  public mutating func clearSessionCookie(name: String = "robin-session") {
    precondition(Self.isSafeCookieComponent(name))
    head.headerFields.append(
      HTTPField(
        name: .setCookie,
        value: "\(name)=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax"))
  }

  private static func isSafeCookieComponent(_ value: String) -> Bool {
    !value.isEmpty && !value.contains { $0.isWhitespace || "=;,\"\\".contains($0) }
  }
}
