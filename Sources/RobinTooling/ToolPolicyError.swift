/// An invalid value in a Robin tool policy.
public enum ToolPolicyError: Error, Equatable, CustomStringConvertible, Sendable {
  /// The policy uses an unsupported schema version.
  case unsupportedSchema(Int)
  /// The build budget is not positive.
  case invalidBuildBudget

  /// A concise explanation suitable for command-line diagnostics.
  public var description: String {
    switch self {
    case .unsupportedSchema(let version):
      "robin.pkl uses unsupported schema version \(version)."
    case .invalidBuildBudget:
      "robin.pkl requires a positive buildBudgetMilliseconds value."
    }
  }
}
