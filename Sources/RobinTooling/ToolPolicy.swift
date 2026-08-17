/// Tool-only policy loaded from `robin.pkl`.
public struct ToolPolicy: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let lintSeverity: String
  public let buildBudgetMilliseconds: Int

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
