/// An invalid value in a Robin tool policy.
public enum ToolPolicyError: Error, Equatable, Sendable {
  /// The policy uses an unsupported schema version.
  case unsupportedSchema(Int)
  /// The policy contains an unrecognized lint severity.
  case invalidSeverity(String)
  /// The build budget is not positive.
  case invalidBuildBudget
}
