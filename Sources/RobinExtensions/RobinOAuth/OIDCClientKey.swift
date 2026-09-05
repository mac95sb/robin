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
