/// Configurable provider filesystem roots for each neutral artifact role.
public struct ArtifactLayout: Sendable {
  private let roots: [BuildArtifact.Kind: String]

  /// Creates a provider artifact layout.
  ///
  /// Empty roots preserve each artifact's existing relative path.
  ///
  /// - Parameters:
  ///   - staticFiles: The root for files served directly.
  ///   - executables: The root for persistent executables.
  ///   - functionBundles: The root for deployable functions.
  ///   - runtimeLibraries: The root for runtime libraries.
  ///   - routeManifests: The root for routing manifests.
  ///   - deploymentMetadata: The root for other deployment metadata.
  public init(
    staticFiles: String = "",
    executables: String = "",
    functionBundles: String = "",
    runtimeLibraries: String = "",
    routeManifests: String = "",
    deploymentMetadata: String = ""
  ) {
    self.roots = [
      .staticFile: staticFiles,
      .executable: executables,
      .functionBundle: functionBundles,
      .runtimeLibrary: runtimeLibraries,
      .routeManifest: routeManifests,
      .deploymentMetadata: deploymentMetadata,
    ]
  }

  func apply(to artifacts: [BuildArtifact]) throws -> [BuildArtifact] {
    var mappedPaths: [String: String] = [:]
    for artifact in artifacts {
      guard mappedPaths.updateValue(path(for: artifact), forKey: artifact.path) == nil else {
        throw BuildError.duplicateArtifactPath(artifact.path)
      }
    }
    return try artifacts.map { artifact in
      try BuildArtifact(
        kind: artifact.kind,
        path: mappedPaths[artifact.path]!,
        bytes: artifact.bytes,
        dependencies: artifact.dependencies.map { mappedPaths[$0] ?? $0 },
        mediaType: artifact.mediaType,
        integrity: artifact.integrity,
        transforms: artifact.transforms,
        scriptOrigin: artifact.scriptOrigin,
        imageMetadata: artifact.imageMetadata
      )
    }
  }

  private func path(for artifact: BuildArtifact) -> String {
    path(for: artifact.path, kind: artifact.kind)
  }

  func path(for path: String, kind: BuildArtifact.Kind) -> String {
    guard let root = roots[kind], !root.isEmpty else { return path }
    return "\(root)/\(path)"
  }
}
