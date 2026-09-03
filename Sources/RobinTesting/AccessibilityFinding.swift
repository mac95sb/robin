/// One accessibility problem found in a typed component tree.
public struct AccessibilityFinding: Equatable, Sendable {
  /// A stable machine-readable finding identifier.
  public let code: String
  /// A concise description of the problem.
  public let message: String

  /// Creates an accessibility finding.
  ///
  /// - Parameters:
  ///   - code: A stable machine-readable identifier.
  ///   - message: A concise description of the problem.
  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
}
