/// Tool-only policy loaded from `robin.pkl`.
public struct ToolPolicy: Codable, Equatable, Sendable {
  /// The policy schema version understood by the toolchain.
  public let schemaVersion: Int
  /// The configured lint severity name.
  public let lintSeverity: String
  /// The maximum permitted build duration in milliseconds.
  public let buildBudgetMilliseconds: Int

  /// Creates a tool-only policy.
  ///
  /// - Parameters:
  ///   - schemaVersion: The policy schema version.
  ///   - lintSeverity: Either `warning` or `error`.
  ///   - buildBudgetMilliseconds: A positive build-duration budget.
  public init(schemaVersion: Int, lintSeverity: String, buildBudgetMilliseconds: Int) {
    self.schemaVersion = schemaVersion
    self.lintSeverity = lintSeverity
    self.buildBudgetMilliseconds = buildBudgetMilliseconds
  }

  /// Validates the schema version, lint severity, and build budget.
  public func validate() throws(ToolPolicyError) {
    guard schemaVersion == 1 else { throw .unsupportedSchema(schemaVersion) }
    guard ["warning", "error"].contains(lintSeverity) else { throw .invalidSeverity(lintSeverity) }
    guard buildBudgetMilliseconds > 0 else { throw .invalidBuildBudget }
  }
}
