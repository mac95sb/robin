import RobinCore

/// A typed payload that can be scheduled for background execution.
public protocol Job: Codable, Sendable {
  /// Stable name persisted with the encoded payload.
  static var name: String { get }
}
