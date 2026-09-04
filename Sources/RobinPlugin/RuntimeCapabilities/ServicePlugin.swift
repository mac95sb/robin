import RobinCore

/// A plugin that registers typed application services.
public protocol ServicePlugin: Plugin {
  /// Adds the plugin's services to an application configuration.
  ///
  /// - Parameter services: The typed service collection to update.
  func registerServices(in services: inout ConfigurationValues)
}
