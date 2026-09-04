import Crypto
import Foundation
import HTTPTypes
import RobinAuth
import RobinData
import RobinRouting
import RobinServer

/// Starts an OpenID Connect authorization-code flow.
public struct OIDCLoginRoute: APIRoute, ServerRoute {
  /// Route metadata used for conflicts and inspection.
  public let metadata = RouteMetadata(
    operationID: "oidcLogin", summary: "Start OpenID Connect login")
  /// API-root-relative login path.
  public let pattern: RoutePattern
  /// Accepted HTTP method.
  public let method = HTTPMethod.get
  /// The login route does not use an API version segment.
  public let version: Version? = nil
  /// Durable state is required.
  public let requiredCapabilities: TransportCapabilities = .processLocalState

  private let client: OIDCClient
  private let stateStore: any KeyValueStore
  private let now: @Sendable () -> Date

  /// Creates a login route using durable one-time state.
  public init(
    client: OIDCClient,
    stateStore: any KeyValueStore,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.client = client
    self.stateStore = stateStore
    self.now = now
    self.pattern = Self.pattern(for: client.configuration.loginPath)
  }

  /// Redirects a matching request to the provider with PKCE protection.
  public func respond(
    to request: RobinServer.Request,
    context _: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response? {
    guard Self.matches(request, method: method, path: client.configuration.loginPath, api: api)
    else { return nil }
    let state = Self.randomToken()
    let verifier = Self.randomToken()
    let challenge = Self.digest(verifier)
    let record = StateRecord(verifier: verifier)
    let stored = try await stateStore.put(
      try JSONEncoder().encode(record),
      forKey: Self.digest(state),
      namespace: Self.namespace,
      expiresAt: now().addingTimeInterval(600),
      condition: .ifAbsent)
    guard stored else { throw OIDCError.invalidState }
    var response = Response.redirect(
      to: try client.authorizationURL(state: state, codeChallenge: challenge).absoluteString)
    response.setSessionCookie(state, name: Self.cookieName, maximumAge: 600)
    return response
  }
}

/// Completes an OpenID Connect flow and creates a RobinAuth session.
public struct OIDCCallbackRoute: APIRoute, ServerRoute {
  /// Route metadata used for conflicts and inspection.
  public let metadata = RouteMetadata(
    operationID: "oidcCallback", summary: "Complete OpenID Connect login")
  /// API-root-relative callback path.
  public let pattern: RoutePattern
  /// Accepted HTTP method.
  public let method = HTTPMethod.get
  /// The callback route does not use an API version segment.
  public let version: Version? = nil
  /// Durable state is required.
  public let requiredCapabilities: TransportCapabilities = .processLocalState

  private let client: OIDCClient
  private let stateStore: any KeyValueStore
  private let authStore: AuthStore
  private let sessions: AuthSessionManager
  private let now: @Sendable () -> Date

  /// Creates a callback route that links identities and creates RobinAuth sessions.
  public init(
    client: OIDCClient,
    stateStore: any KeyValueStore,
    authStore: AuthStore,
    sessions: AuthSessionManager,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.client = client
    self.stateStore = stateStore
    self.authStore = authStore
    self.sessions = sessions
    self.now = now
    self.pattern = OIDCLoginRoute.pattern(for: client.configuration.callbackPath)
  }

  /// Completes a matching provider callback.
  public func respond(
    to request: RobinServer.Request,
    context _: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response? {
    guard
      OIDCLoginRoute.matches(
        request, method: method, path: client.configuration.callbackPath, api: api)
    else { return nil }
    guard let state = Self.queryValue("state", in: request),
      let code = Self.queryValue("code", in: request),
      request.cookie(named: OIDCLoginRoute.cookieName) == state,
      let data = try await stateStore.consumeValue(
        forKey: OIDCLoginRoute.digest(state), namespace: OIDCLoginRoute.namespace, at: now()),
      let record = try? JSONDecoder().decode(StateRecord.self, from: data)
    else { return Self.rejected() }

    let identity = try await client.identity(code: code, verifier: record.verifier)
    let account = try await resolveAccount(identity)
    let token = try await sessions.create(for: account.id)
    var response = Response.redirect(to: client.configuration.successRedirect)
    response.clearSessionCookie(name: OIDCLoginRoute.cookieName)
    response.setAuthSessionCookie(token, now: now())
    return response
  }

  private func resolveAccount(_ identity: OIDCIdentity) async throws -> Account {
    if let email = identity.verifiedEmail,
      let account = try await authStore.account(verifiedEmail: email, at: now())
    {
      return account
    }
    let id = OIDCLoginRoute.digest(
      "\(client.configuration.issuer.absoluteString)|\(identity.subject)")
    if let account = try await authStore.account(id: id, at: now()) { return account }
    let account = try Account(
      id: id,
      name: identity.name ?? identity.verifiedEmail ?? "OpenID Connect user",
      verifiedEmail: identity.verifiedEmail,
      createdAt: now())
    try await authStore.save(account, at: now())
    return account
  }

  private static func queryValue(_ name: String, in request: RobinServer.Request) -> String? {
    URLComponents(string: "?\(request.query ?? "")")?.queryItems?.first { $0.name == name }?.value
  }

  private static func rejected() -> Response {
    var response = Response.text("Invalid login state", status: .unauthorized)
    response.clearSessionCookie(name: OIDCLoginRoute.cookieName)
    return response
  }
}

private struct StateRecord: Codable, Sendable { let verifier: String }

extension OIDCLoginRoute {
  fileprivate static let namespace = "robin.oauth.state"
  fileprivate static let cookieName = "robin-oidc-state"

  fileprivate static func pattern(for path: String) -> RoutePattern {
    RoutePattern(path.split(separator: "/").map { .literal(String($0)) })
  }

  fileprivate static func matches(
    _ request: RobinServer.Request,
    method: HTTPMethod,
    path: String,
    api: APIConfiguration
  ) -> Bool {
    request.path == api.root.value + path
      && request.method.rawValue.caseInsensitiveCompare(method.rawValue) == .orderedSame
  }

  fileprivate static func randomToken() -> String {
    var generator = SystemRandomNumberGenerator()
    return Data((0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
      .base64URLEncoded
  }

  fileprivate static func digest(_ value: String) -> String {
    Data(SHA256.hash(data: Data(value.utf8))).base64URLEncoded
  }
}

extension Data {
  fileprivate var base64URLEncoded: String {
    base64EncodedString().replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
  }
}
