import Foundation
import RobinAuth
import RobinCore
import RobinData
import RobinPlugin

/// Typed service key for the configured OpenID Connect client.
public struct OIDCClientKey: ConfigurationKey {
  private init() {}
  /// No OpenID Connect client is registered by default.
  public static let defaultValue: OIDCClient? = nil
}

/// OpenID Connect login integration for RobinAuth.
public struct OIDCPlugin: RoutePlugin, ServicePlugin {
  /// Configured provider client.
  public let client: OIDCClient
  /// Route that starts login.
  public let login: OIDCLoginRoute
  /// Route that completes login.
  public let callback: OIDCCallbackRoute

  /// Creates the provider client, routes, durable state, and session integration.
  public init(
    client: OIDCClient,
    stateStore: any KeyValueStore,
    authStore: AuthStore,
    sessions: AuthSessionManager,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.client = client
    self.login = OIDCLoginRoute(client: client, stateStore: stateStore, now: now)
    self.callback = OIDCCallbackRoute(
      client: client, stateStore: stateStore, authStore: authStore, sessions: sessions, now: now)
  }

  /// Registers the login and callback routes.
  public var routes: [any ApplicationRoute] { [login, callback] }

  /// Registers the configured client as a typed service.
  public func registerServices(in services: inout ConfigurationValues) {
    services[OIDCClientKey.self] = client
  }
}
