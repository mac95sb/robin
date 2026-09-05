import RobinCore
import RobinJobs
import RobinPlugin

/// Typed service key for the configured Polar client.
public struct PolarClientKey: ConfigurationKey {
  private init() {}
  /// No Polar client is registered by default.
  public static let defaultValue: PolarClient? = nil
}
