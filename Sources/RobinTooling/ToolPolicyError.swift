/// An invalid value in a Robin tool policy.
public enum ToolPolicyError: Error, Equatable, Sendable {
  case unsupportedSchema(Int)
  case invalidSeverity(String)
  case invalidBuildBudget
}
