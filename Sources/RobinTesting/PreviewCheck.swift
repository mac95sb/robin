/// One synchronous check associated with a component preview.
public struct PreviewCheck: Sendable {
  /// The check's display name.
  public let name: String
  private let operation: @Sendable () throws -> Void

  /// Creates a named preview check.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - operation: The assertion work to run when generating the dashboard.
  public init(_ name: String, operation: @escaping @Sendable () throws -> Void) {
    precondition(name.contains { !$0.isWhitespace })
    self.name = name
    self.operation = operation
  }

  func result() -> PreviewCheckResult {
    do {
      try operation()
      return .init(name: name, outcome: .passed)
    } catch {
      return .init(name: name, outcome: .failed(String(describing: error)))
    }
  }
}

/// The result of running a preview check.
public struct PreviewCheckResult: Equatable, Sendable {
  /// A preview-check outcome.
  public enum Outcome: Equatable, Sendable {
    /// The check completed without throwing.
    case passed
    /// The check threw with the supplied diagnostic.
    case failed(String)
  }

  /// The check's display name.
  public let name: String
  /// The check's outcome.
  public let outcome: Outcome

  /// Creates a preview-check result.
  ///
  /// - Parameters:
  ///   - name: The check's display name.
  ///   - outcome: The check's outcome.
  public init(name: String, outcome: Outcome) {
    self.name = name
    self.outcome = outcome
  }
}
