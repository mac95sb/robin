import RobinCore

/// A structural error in a build artifact graph.
public enum BuildError: Error, Equatable, Sendable {
  /// An artifact path is empty, absolute, reserved, or contains an unsafe component.
  case invalidArtifactPath(String)
  /// Two artifacts produce the same relative path.
  case duplicateArtifactPath(String)
  /// An artifact names a dependency absent from the graph.
  case missingDependency(artifact: String, dependency: String)
  /// Artifact dependencies contain a cycle, reported in traversal order.
  case dependencyCycle([String])
  /// A resolved output path escapes the project's `.robin` directory.
  case outputEscapesRobinRoot(String)
  /// A page path cannot be represented as a clean static output path.
  case invalidPagePath(String)
  /// Two registered pages resolve to the same static output path.
  case duplicatePagePath(String)
  /// A page declares the same structured-data schema more than once.
  case duplicateStructuredData(String)
  /// The application selected a theme RobinBuild cannot compile.
  case unsupportedTheme
  /// A static application was configured with executable output.
  case staticApplicationHasExecutableArtifacts
  /// An API or SSR application has no executable artifact.
  case missingExecutableArtifact(ApplicationMode)
  /// A JavaScript artifact has no typed provenance.
  case unexplainedScript(String)
  /// Script provenance was attached to a non-JavaScript artifact.
  case invalidScriptOrigin(String)
  /// A transform requested a tool absent from the configured toolchain.
  case missingAssetTool(String)
  /// A configured asset tool does not match its pinned digest.
  case assetToolDigestMismatch(String)
  /// A configured asset tool failed or did not produce output.
  case assetToolFailed(String, status: Int32, diagnostic: String)
  /// A remote asset has no required production digest.
  case unpinnedRemoteAsset(String)
  /// Downloaded remote bytes do not match their pinned digest.
  case remoteAssetDigestMismatch(String)
  /// A remote asset could not be downloaded.
  case remoteAssetUnavailable(String)
  /// Remote assets require the asynchronous build entry point.
  case remoteAssetsRequireAsyncBuild
  /// A CDN base URL is not an absolute HTTPS URL.
  case invalidCDNBaseURL(String)
  /// Bytes declared as a supported raster image contain no valid dimensions.
  case invalidImage(String)
  /// A speculation rule names a page not registered by the application.
  case unknownSpeculationRoute(String)
  /// A speculation rule names an asset absent from the typed asset graph.
  case unknownSpeculationAsset(String)
  /// A provider-neutral deployment route contains an unsafe pattern or destination.
  case invalidDeploymentRoute(String)
  /// SSR prerendering selected a page absent from the application.
  case unknownPrerenderedPage(String)
  /// A content-addressed cache entry does not match its digest.
  case corruptedCacheEntry(String)
  /// A resource hint is incompatible with its asset or does not contain a valid origin.
  case invalidResourceHint(String)
  /// A supplied SHA-256 digest is not 64 hexadecimal characters.
  case invalidDigest(String)
}
