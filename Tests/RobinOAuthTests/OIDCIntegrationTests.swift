import Foundation
import HTTPTypes
import RobinAuth
import RobinCore
import RobinData
import RobinOAuth
import RobinServer
import Testing

@Suite("OpenID Connect integration")
struct OIDCIntegrationTests {
  @Test func rejectsInsecureRemoteEndpoints() throws {
    #expect(throws: OIDCError.invalidConfiguration) {
      try OIDCConfiguration(
        issuer: #require(URL(string: "http://identity.example")),
        authorizationEndpoint: #require(URL(string: "https://identity.example/authorize")),
        tokenEndpoint: #require(URL(string: "https://identity.example/token")),
        userInfoEndpoint: #require(URL(string: "https://identity.example/userinfo")),
        clientID: "client",
        callbackURL: #require(URL(string: "https://app.example/api/auth/oidc/callback")))
    }
  }

  @Test func loginUsesPKCEAndCallbackCreatesSingleUseSession() async throws {
    let now = Date(timeIntervalSince1970: 2_000)
    let database = try await SQLiteDatabase()
    let keyValues = try await DatabaseKeyValueStore(database: database, now: { now })
    let authStore = AuthStore(keyValues)
    let sessions = AuthSessionManager(store: authStore, now: { now })
    let configuration = try OIDCConfiguration(
      issuer: #require(URL(string: "https://identity.example")),
      authorizationEndpoint: #require(URL(string: "https://identity.example/authorize")),
      tokenEndpoint: #require(URL(string: "https://identity.example/token")),
      userInfoEndpoint: #require(URL(string: "https://identity.example/userinfo")),
      clientID: "client",
      callbackURL: #require(URL(string: "https://app.example/api/auth/oidc/callback")),
      successRedirect: "/account")
    let requests = RequestCapture()
    let client = OIDCClient(configuration: configuration) { request in
      await requests.record(request)
      if request.url?.path == "/token" {
        return OIDCHTTPResponse(statusCode: 200, body: Data(#"{"access_token":"access"}"#.utf8))
      }
      return OIDCHTTPResponse(
        statusCode: 200,
        body: Data(
          #"{"sub":"person-1","name":"Person","email":"person@example.com","email_verified":true}"#
            .utf8))
    }
    let plugin = OIDCPlugin(
      client: client, stateStore: keyValues, authStore: authStore, sessions: sessions, now: { now })
    let responder = try ApplicationResponder(
      routes: [plugin.login, plugin.callback], transportCapabilities: .persistent)

    let login = await responder.respond(
      to: Request(
        HTTPRequest(
          method: .get, scheme: "https", authority: "app.example", path: "/api/auth/oidc/login")))
    let location = try #require(login.head.headerFields[.location])
    let authorization = try #require(URLComponents(string: location))
    let state = try #require(authorization.queryItems?.first { $0.name == "state" }?.value)
    #expect(authorization.queryItems?.first { $0.name == "code_challenge_method" }?.value == "S256")
    let stateCookie = try #require(login.head.headerFields[fields: .setCookie].first?.value)

    let callback = await responder.respond(
      to: Request(
        HTTPRequest(
          method: .get,
          scheme: "https",
          authority: "app.example",
          path: "/api/auth/oidc/callback?state=\(state)&code=provider-code",
          headerFields: [.cookie: stateCookie])))
    #expect(callback.head.status == .seeOther)
    #expect(callback.head.headerFields[.location] == "/account")
    let sessionCookie = try #require(
      callback.head.headerFields[fields: .setCookie].map(\.value).first {
        $0.hasPrefix("robin-session=")
      })
    let token = try #require(sessionCookie.split(separator: ";").first?.split(separator: "=").last)
      .description
    let session = try await sessions.session(for: token)
    #expect(
      try await authStore.account(id: session.accountID)?.verifiedEmail == "person@example.com")
    #expect(await requests.requests.map(\.url?.path) == ["/token", "/userinfo"])

    let replay = await responder.respond(
      to: Request(
        HTTPRequest(
          method: .get,
          scheme: "https",
          authority: "app.example",
          path: "/api/auth/oidc/callback?state=\(state)&code=provider-code",
          headerFields: [.cookie: stateCookie])))
    #expect(replay.head.status == .unauthorized)
    try await database.shutdown()
  }
}

private actor RequestCapture {
  var requests: [URLRequest] = []
  func record(_ request: URLRequest) { requests.append(request) }
}
