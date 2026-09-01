import Collections
import Foundation

/// A bounded process-local session store for persistent server deployments.
public actor SessionStore<Value: Sendable> {
  private struct Record: Sendable {
    let value: Value
    let expiresAt: Date
  }

  private let capacity: Int
  private let lifetime: TimeInterval
  private let now: @Sendable () -> Date
  private var records: OrderedDictionary<String, Record> = [:]

  /// Creates a process-local session store.
  ///
  /// - Parameters:
  ///   - capacity: The positive maximum number of sessions retained.
  ///   - lifetime: The positive lifetime of each session, in seconds.
  ///   - now: The clock used to expire sessions.
  public init(
    capacity: Int = 10_000,
    lifetime: TimeInterval = 86_400,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    precondition(capacity > 0 && lifetime > 0)
    self.capacity = capacity
    self.lifetime = lifetime
    self.now = now
  }

  /// Stores a value and returns a new cryptographically random token.
  public func create(_ value: Value) -> String {
    removeExpired()
    let token = Self.token()
    records[token] = Record(value: value, expiresAt: now().addingTimeInterval(lifetime))
    if records.count > capacity { records.removeFirst() }
    return token
  }

  /// Returns the value for an unexpired token.
  public func value(for token: String) -> Value? {
    guard let record = records[token] else { return nil }
    guard record.expiresAt > now() else {
      records.removeValue(forKey: token)
      return nil
    }
    return record.value
  }

  /// Replaces a valid token while preserving its value.
  ///
  /// - Returns: The replacement token, or `nil` when the original is absent or expired.
  public func rotate(_ token: String) -> String? {
    guard let value = value(for: token) else { return nil }
    records.removeValue(forKey: token)
    return create(value)
  }

  /// Invalidates a token if it exists.
  public func revoke(_ token: String) {
    records.removeValue(forKey: token)
  }

  private func removeExpired() {
    let instant = now()
    records.removeAll { $0.value.expiresAt <= instant }
  }

  private static func token() -> String {
    var generator = SystemRandomNumberGenerator()
    let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
    return Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
