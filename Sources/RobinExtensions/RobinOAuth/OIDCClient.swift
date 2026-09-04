import Crypto
import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Provider endpoints and credentials for an OpenID Connect authorization-code flow.
public struct OIDCConfiguration: Sendable {
  /// Provider issuer identifier.
  public let issuer: URL
  /// Provider authorization endpoint.
  public let authorizationEndpoint: URL
  /// Provider token endpoint.
  public let tokenEndpoint: URL
  /// Provider user-info endpoint.
  public let userInfoEndpoint: URL
  /// Registered OAuth client identifier.
  public let clientID: String
  /// Optional confidential-client secret.
  public let clientSecret: Secret<String>?
  /// Absolute callback URL registered with the provider.
  public let callbackURL: URL
  /// API-root-relative path that starts login.
  public let loginPath: String
  /// API-root-relative path that completes login.
  public let callbackPath: String
  /// Root-relative destination after login.
  public let successRedirect: String
  /// Requested OpenID Connect scopes.
  public let scopes: [String]

  /// Creates a validated provider configuration.
  public init(
    issuer: URL,
    authorizationEndpoint: URL,
    tokenEndpoint: URL,
    userInfoEndpoint: URL,
    clientID: String,
    clientSecret: Secret<String>? = nil,
    callbackURL: URL,
    loginPath: String = "/auth/oidc/login",
    callbackPath: String = "/auth/oidc/callback",
    successRedirect: String = "/",
    scopes: [String] = ["openid", "profile", "email"]
  ) throws {
    let urls = [issuer, authorizationEndpoint, tokenEndpoint, userInfoEndpoint, callbackURL]
    guard !clientID.isEmpty, scopes.contains("openid"), urls.allSatisfy(Self.isHTTPURL),
      Self.isRoutePath(loginPath), Self.isRoutePath(callbackPath),
      Self.isRoutePath(successRedirect)
    else { throw OIDCError.invalidConfiguration }
    self.issuer = issuer
    self.authorizationEndpoint = authorizationEndpoint
    self.tokenEndpoint = tokenEndpoint
    self.userInfoEndpoint = userInfoEndpoint
    self.clientID = clientID
    self.clientSecret = clientSecret
    self.callbackURL = callbackURL
    self.loginPath = loginPath
    self.callbackPath = callbackPath
    self.successRedirect = successRedirect
    self.scopes = scopes
  }

  private static func isHTTPURL(_ url: URL) -> Bool {
    guard let host = url.host, url.user == nil, url.password == nil else { return false }
    return url.scheme == "https"
      || (url.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(host))
  }

  private static func isRoutePath(_ path: String) -> Bool {
    path.hasPrefix("/") && !path.hasPrefix("//") && !path.contains("\r")
      && !path.contains("\n") && !path.split(separator: "/").contains("..")
  }
}

/// A transport response used by ``OIDCClient``.
public struct OIDCHTTPResponse: Sendable {
  /// Provider HTTP status code.
  public let statusCode: Int
  /// Complete provider response body.
  public let body: Data

  /// Creates a transport response.
  public init(statusCode: Int, body: Data) {
    self.statusCode = statusCode
    self.body = body
  }
}

/// Verified identity returned by an OpenID Connect provider.
public struct OIDCIdentity: Equatable, Sendable {
  /// Provider-stable subject identifier.
  public let subject: String
  /// Optional display name.
  public let name: String?
  /// Email address only when the provider reported it as verified.
  public let verifiedEmail: String?
}

/// Minimal OpenID Connect authorization-code client with PKCE.
public struct OIDCClient: Sendable {
  /// Request execution supplied by URLSession in production and replaceable in tests.
  public typealias Transport = @Sendable (URLRequest) async throws -> OIDCHTTPResponse

  /// Validated provider configuration.
  public let configuration: OIDCConfiguration
  private let transport: Transport

  /// Creates a client backed by an ephemeral URL session.
  public init(configuration: OIDCConfiguration) {
    self.init(configuration: configuration) { request in
      let sessionConfiguration = URLSessionConfiguration.ephemeral
      sessionConfiguration.timeoutIntervalForRequest = 30
      let (data, response) = try await URLSession(configuration: sessionConfiguration).data(
        for: request)
      guard let response = response as? HTTPURLResponse else { throw OIDCError.invalidResponse }
      return OIDCHTTPResponse(statusCode: response.statusCode, body: data)
    }
  }

  /// Creates a client with an explicit transport.
  public init(configuration: OIDCConfiguration, transport: @escaping Transport) {
    self.configuration = configuration
    self.transport = transport
  }

  /// Builds the provider authorization URL for a state value and PKCE challenge.
  public func authorizationURL(state: String, codeChallenge: String) throws -> URL {
    guard !state.isEmpty, !codeChallenge.isEmpty,
      var components = URLComponents(
        url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: false)
    else { throw OIDCError.invalidInput }
    components.queryItems =
      (components.queryItems ?? []) + [
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "client_id", value: configuration.clientID),
        URLQueryItem(name: "redirect_uri", value: configuration.callbackURL.absoluteString),
        URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
        URLQueryItem(name: "state", value: state),
        URLQueryItem(name: "code_challenge", value: codeChallenge),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
      ]
    guard let url = components.url else { throw OIDCError.invalidConfiguration }
    return url
  }

  /// Exchanges a provider code and resolves its verified user-info identity.
  public func identity(code: String, verifier: String) async throws -> OIDCIdentity {
    guard !code.isEmpty, !verifier.isEmpty else { throw OIDCError.invalidInput }
    var fields = [
      "grant_type": "authorization_code",
      "code": code,
      "redirect_uri": configuration.callbackURL.absoluteString,
      "client_id": configuration.clientID,
      "code_verifier": verifier,
    ]
    configuration.clientSecret?.withValue { fields["client_secret"] = String($0) }
    var tokenRequest = URLRequest(url: configuration.tokenEndpoint)
    tokenRequest.httpMethod = "POST"
    tokenRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    tokenRequest.setValue(
      "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    tokenRequest.httpBody = Data(Self.formEncoded(fields).utf8)
    let token: TokenResponse = try await send(tokenRequest)
    guard !token.accessToken.isEmpty else { throw OIDCError.invalidResponse }

    var userRequest = URLRequest(url: configuration.userInfoEndpoint)
    userRequest.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
    userRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    let user: UserInfo = try await send(userRequest)
    guard !user.subject.isEmpty else { throw OIDCError.invalidResponse }
    return OIDCIdentity(
      subject: user.subject,
      name: user.name ?? user.preferredUsername,
      verifiedEmail: user.emailVerified == true ? user.email : nil)
  }

  private func send<Value: Decodable>(_ request: URLRequest) async throws -> Value {
    let response = try await transport(request)
    guard (200..<300).contains(response.statusCode) else {
      throw OIDCError.providerStatus(response.statusCode)
    }
    do { return try JSONDecoder().decode(Value.self, from: response.body) } catch {
      throw OIDCError.invalidResponse
    }
  }

  private static func formEncoded(_ fields: [String: String]) -> String {
    fields.sorted { $0.key < $1.key }.map {
      "\(formComponent($0.key))=\(formComponent($0.value))"
    }.joined(separator: "&")
  }

  private static func formComponent(_ value: String) -> String {
    value.addingPercentEncoding(
      withAllowedCharacters: CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")) ?? ""
  }
}

/// OpenID Connect failures that do not expose provider response bodies or credentials.
public enum OIDCError: Error, Equatable, Sendable {
  /// Provider configuration is incomplete or unsafe.
  case invalidConfiguration
  /// An operation received invalid input.
  case invalidInput
  /// The provider returned an unsuccessful HTTP status.
  case providerStatus(Int)
  /// The provider returned an unusable response.
  case invalidResponse
  /// Browser state was missing, expired, mismatched, or already consumed.
  case invalidState
}

private struct TokenResponse: Decodable {
  let accessToken: String

  enum CodingKeys: String, CodingKey { case accessToken = "access_token" }
}

private struct UserInfo: Decodable {
  let subject: String
  let name: String?
  let preferredUsername: String?
  let email: String?
  let emailVerified: Bool?

  enum CodingKeys: String, CodingKey {
    case subject = "sub"
    case name
    case preferredUsername = "preferred_username"
    case email
    case emailVerified = "email_verified"
  }
}
