/// A plugin that participates in application startup and shutdown.
public protocol LifecyclePlugin: Plugin {
  /// Starts the plugin after application services have been registered.
  func start() async throws

  /// Stops the plugin during graceful application shutdown.
  func stop() async throws
}
