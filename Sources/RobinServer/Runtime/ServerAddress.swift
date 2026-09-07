import Foundation

/// The network address bound by a running server.
public struct ServerAddress: Equatable, Sendable {
  /// The bound IP address.
  public let host: String

  /// The bound TCP port.
  public let port: Int

  /// The default loopback address, using `PORT` when the environment provides one.
  public static var environment: Self {
    .init(host: "127.0.0.1", port: Int(ProcessInfo.processInfo.environment["PORT"] ?? "") ?? 8080)
  }

  /// Creates a server address.
  ///
  /// - Parameters:
  ///   - host: An IPv4 or IPv6 address.
  ///   - port: A TCP port from 0 through 65,535.
  public init(host: String, port: Int) {
    precondition((0...65_535).contains(port))
    self.host = host
    self.port = port
  }
}
