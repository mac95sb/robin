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
