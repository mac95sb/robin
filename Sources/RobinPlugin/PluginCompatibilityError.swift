/// An incompatible plugin and host API combination.
public struct PluginCompatibilityError: Error, Equatable, Sendable {
  /// The incompatible plugin type name.
  public let plugin: String
  /// The plugin API versions accepted by the plugin.
  public let supported: ClosedRange<PluginAPIVersion>
  /// The plugin API version implemented by the host.
  public let host: PluginAPIVersion

  /// Creates an incompatibility error.
  public init(
    plugin: String,
    supported: ClosedRange<PluginAPIVersion>,
    host: PluginAPIVersion
  ) {
    self.plugin = plugin
    self.supported = supported
    self.host = host
  }
}
