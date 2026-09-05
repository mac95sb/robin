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
