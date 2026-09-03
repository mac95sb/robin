import RobinCore

/// Runtime features that a request transport can preserve without degradation.
public struct TransportCapabilities: OptionSet, Sendable {
  /// The underlying capability bit set.
  public let rawValue: UInt8

  /// Creates a capability set from its raw representation.
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  /// Supports asynchronous response streaming with backpressure.
  public static let streaming = Self(rawValue: 1 << 0)
  /// Supports long-lived server-sent event responses.
  public static let serverSentEvents = Self(rawValue: 1 << 1)
  /// Supports full-duplex WebSocket connections.
  public static let webSockets = Self(rawValue: 1 << 2)
  /// Preserves state held by one long-running process.
  public static let processLocalState = Self(rawValue: 1 << 3)
  /// Provides a filesystem that survives requests and process restarts.
  public static let persistentFileSystem = Self(rawValue: 1 << 4)
  /// Capabilities currently provided by the persistent HTTP adapter.
  public static let persistent: Self = [
    .streaming, .serverSentEvents, .webSockets, .processLocalState, .persistentFileSystem,
  ]
}

/// Diagnostics for features unavailable on a selected transport.
public struct TransportCapabilityError: Error, Equatable, Sendable {
  /// Actionable diagnostics for every missing capability.
  public let diagnostics: [Diagnostic]

  /// Creates diagnostics by subtracting available capabilities from required capabilities.
  public init(required: TransportCapabilities, available: TransportCapabilities) {
    let missing = required.subtracting(available)
    self.diagnostics = [
      (.webSockets, "WebSockets"),
      (.serverSentEvents, "server-sent events"),
      (.streaming, "streaming responses"),
      (.processLocalState, "process-local state"),
      (.persistentFileSystem, "a persistent filesystem"),
    ].compactMap { capability, name in
      missing.contains(capability)
        ? Diagnostic(.error, "The selected transport does not support \(name).") : nil
    }
  }
}
