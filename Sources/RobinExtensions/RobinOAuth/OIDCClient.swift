import Crypto
import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

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
