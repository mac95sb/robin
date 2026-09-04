import RobinBuild

/// A plugin that transforms the final build artifact graph.
public protocol BuildTransformPlugin: Plugin {
  /// Transforms build artifacts without changing their deployment-neutral representation.
  ///
  /// - Parameter artifacts: The artifacts produced by the preceding build stage.
  /// - Returns: The artifacts for the next stage.
  /// - Throws: An error raised while transforming the artifacts.
  func transform(_ artifacts: [BuildArtifact]) async throws -> [BuildArtifact]
}
