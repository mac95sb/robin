/// Tool-only policy loaded from `robin.pkl`.
public struct ToolPolicy: Codable, Equatable, Sendable {
  /// The minimum severity applied to lint findings.
  public enum LintSeverity: String, Codable, Sendable {
    /// Report findings without failing the command.
    case warning
    /// Treat every finding as a command failure.
    case error
  }

  /// The policy schema version understood by the toolchain.
  public let schemaVersion: Int
  /// The minimum severity applied to lint findings.
  public let lintSeverity: LintSeverity
  /// The maximum permitted build duration in milliseconds.
  public let buildBudgetMilliseconds: Int

  /// Creates a tool-only policy.
  ///
  /// - Parameters:
  ///   - schemaVersion: The policy schema version.
  ///   - lintSeverity: The minimum severity applied to lint findings.
  ///   - buildBudgetMilliseconds: A positive build-duration budget.
  public init(
    schemaVersion: Int,
    lintSeverity: LintSeverity,
    buildBudgetMilliseconds: Int
  ) {
    self.schemaVersion = schemaVersion
    self.lintSeverity = lintSeverity
    self.buildBudgetMilliseconds = buildBudgetMilliseconds
  }

  /// Validates the schema version and build budget.
  public func validate() throws(ToolPolicyError) {
    guard schemaVersion == 1 else { throw .unsupportedSchema(schemaVersion) }
    guard buildBudgetMilliseconds > 0 else { throw .invalidBuildBudget }
  }
}
