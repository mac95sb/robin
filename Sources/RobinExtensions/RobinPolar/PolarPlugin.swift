import RobinCore
import RobinJobs
import RobinPlugin

/// Typed service key for the configured Polar client.
public struct PolarClientKey: ConfigurationKey {
  private init() {}
  /// No Polar client is registered by default.
  public static let defaultValue: PolarClient? = nil
}

/// Polar checkout, subscription, and webhook integration.
public struct PolarPlugin: RoutePlugin, ServicePlugin {
  /// Configured API client.
  public let client: PolarClient
  /// Verified webhook route.
  public let webhook: PolarWebhookRoute

  /// Creates the Polar plugin.
  public init(
    client: PolarClient,
    webhookSecret: Secret<String>,
    jobs: JobClient,
    webhookPath: String = "/_robin/polar/webhook",
    tenant: TenantScope<String> = .none
  ) throws {
    self.client = client
    self.webhook = try PolarWebhookRoute(
      path: webhookPath, secret: webhookSecret, jobs: jobs, tenant: tenant)
  }

  /// Registers Polar's webhook route.
  public var routes: [any ApplicationRoute] { [webhook] }

  /// Registers the configured client as a typed service.
  public func registerServices(in services: inout ConfigurationValues) {
    services[PolarClientKey.self] = client
  }
}
