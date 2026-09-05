import RobinCore

/// Runtime features that a request transport can preserve without degradation.
public struct TransportCapabilities: OptionSet, Sendable {
  /// The underlying capability bit set.
  public let rawValue: UInt16

  /// Creates a capability set from its raw representation.
  public init(rawValue: UInt16) { self.rawValue = rawValue }

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
  /// Allows the application to bind a listening socket.
  public static let listeningSockets = Self(rawValue: 1 << 5)
  /// Allows outbound network connections.
  public static let outboundNetworking = Self(rawValue: 1 << 6)
  /// Allows native operating-system threads.
  public static let threads = Self(rawValue: 1 << 7)
  /// Allows child processes.
  public static let subprocesses = Self(rawValue: 1 << 8)
  /// Provides writable storage that may be discarded after an invocation.
  public static let writableFileSystem = Self(rawValue: 1 << 9)
  /// Provides wall and monotonic clocks.
  public static let clocks = Self(rawValue: 1 << 10)
  /// Provides cryptographically secure random bytes.
  public static let secureRandomness = Self(rawValue: 1 << 11)
  /// Capabilities currently provided by the persistent HTTP adapter.
  public static let persistent: Self = [
    .streaming, .serverSentEvents, .webSockets, .processLocalState, .persistentFileSystem,
    .listeningSockets, .outboundNetworking, .threads, .subprocesses, .writableFileSystem, .clocks,
    .secureRandomness,
  ]
  /// Capabilities provided by the first-party AWS Lambda adapter.
  public static let lambda: Self = [
    .outboundNetworking, .threads, .subprocesses, .writableFileSystem, .clocks, .secureRandomness,
  ]
  /// Capabilities guaranteed by an unspecified invocation provider.
  public static let invocation: Self = []
}
