/// A category of generated output stored under the `.robin` directory.
public enum RobinArtifact: String, CaseIterable, Sendable {
  /// Compiled application output.
  case build
  /// Reusable cached data.
  case cache
  /// Test and documentation coverage reports.
  case coverage
  /// Exported deployment output.
  case export
  /// Generated source and metadata.
  case generated
  /// Inspector application state.
  case inspector
  /// Build and runtime logs.
  case logs
  /// Preview-server output.
  case preview
  /// Structured test results.
  case testResults
  /// Short-lived intermediate output.
  case temporary
}
