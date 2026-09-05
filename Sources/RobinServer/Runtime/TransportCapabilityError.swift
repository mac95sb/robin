import RobinCore

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
      (.listeningSockets, "listening sockets"),
      (.outboundNetworking, "outbound networking"),
      (.threads, "native threads"),
      (.subprocesses, "subprocesses"),
      (.writableFileSystem, "a writable filesystem"),
      (.clocks, "clocks"),
      (.secureRandomness, "secure randomness"),
    ].compactMap { capability, name in
      missing.contains(capability)
        ? Diagnostic(.error, "The selected transport does not support \(name).") : nil
    }
  }
}
