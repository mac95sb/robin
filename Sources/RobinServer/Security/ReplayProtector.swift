import Collections

/// A bounded process-local replay guard for verified webhook identifiers.
public actor ReplayProtector {
  private let capacity: Int
  private var identifiers: OrderedSet<String> = []

  /// Creates a bounded replay-protection window.
  ///
  /// - Parameter capacity: The positive number of identifiers retained.
  public init(capacity: Int = 10_000) {
    precondition(capacity > 0)
    self.capacity = capacity
  }

  /// Returns `true` only for the first observation of an identifier still in the window.
  public func accept(_ identifier: String) -> Bool {
    guard identifiers.append(identifier).inserted else { return false }
    if identifiers.count > capacity { identifiers.removeFirst() }
    return true
  }
}
