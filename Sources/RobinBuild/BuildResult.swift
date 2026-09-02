import RobinCore

/// The inferred application mode and materialized artifact manifest from a build.
public struct BuildResult: Equatable, Sendable {
  /// The mode inferred from registered pages and controllers.
  public let mode: ApplicationMode
  /// The manifest describing every materialized artifact.
  public let manifest: BuildManifest
}
