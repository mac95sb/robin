/// A category of generated output stored under the `.robin` directory.
public enum RobinArtifact: String, CaseIterable, Sendable {
  case build, cache, coverage, generated, inspector, logs, preview, testResults, temporary
}
