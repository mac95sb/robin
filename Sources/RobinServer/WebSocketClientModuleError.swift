import RobinBuild

/// Invalid or ambiguous WebSocket browser binding.
public enum WebSocketClientModuleError: Error, Equatable, Sendable {
  /// A path or element identifier is unsafe or ambiguous.
  case invalidConfiguration
}
