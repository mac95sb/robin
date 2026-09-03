import Foundation
import RobinCore
import RobinStyle

/// Settings that affect generated build artifacts without changing application mode.
public struct BuildConfiguration: Sendable {
  /// The validation policy for local and production builds.
  public var environment: BuildEnvironment
  /// The stylesheet formatting used for generated CSS.
  public var cssOutputMode: CSSOutputMode
  /// Whether generated styles enable native cross-document view transitions.
  public var viewTransitions: ViewTransitionNavigation
  /// Executables, WebAssembly components, adapters, and libraries supplied by the build frontend.
  public var runtimeArtifacts: [BuildArtifact]
  /// Typed local assets to transform and fingerprint.
  public var assets: [BuildAsset]
  /// Typed remote assets fetched only by the asynchronous build entry point.
  public var remoteAssets: [RemoteAsset]
  /// Checksum-pinned external asset tools.
  public var assetToolchain: AssetToolchain
  /// An optional base URL used for generated asset references.
  public var cdnBaseURL: URL?
  /// Typed route candidates for declarative prefetching and prerendering.
  public var speculationRules: [SpeculationRule]
  /// Provider-neutral deployment routes supplied by the build frontend.
  public var deploymentRoutes: [DeploymentRoute]
  /// The optional encoder for a provider routing manifest.
  public var routingManifestEncoder: (any RoutingManifestEncoder)?
  /// Provider filesystem roots applied after neutral artifact generation.
  public var artifactLayout: ArtifactLayout
  /// Runtime contracts attached to executable or WebAssembly artifacts.
  public var runtimes: [DeploymentRuntime]
  /// SSR page paths explicitly eligible for deterministic prerendering.
  public var prerenderedPagePaths: Set<String>

  /// Creates build settings.
  ///
  /// - Parameters:
  ///   - environment: The validation policy for local and production builds.
  ///   - cssOutputMode: The stylesheet formatting used for generated CSS.
  ///   - viewTransitions: Whether to emit native cross-document transition CSS.
  ///   - runtimeArtifacts: Compiled executables, WebAssembly components, adapters, and libraries.
  ///   - assets: Typed local assets to process.
  ///   - remoteAssets: Typed remote assets fetched during an asynchronous build.
  ///   - assetToolchain: Checksum-pinned external asset tools.
  ///   - cdnBaseURL: An optional base URL for generated asset references.
  ///   - speculationRules: Typed route candidates for browser speculation.
  ///   - deploymentRoutes: Provider-neutral routes to encode.
  ///   - routingManifestEncoder: The optional provider routing-manifest encoder.
  ///   - artifactLayout: Provider filesystem roots for final artifacts.
  ///   - runtimes: Runtime contracts attached to executable or WebAssembly artifacts.
  ///   - prerenderedPagePaths: SSR page paths safe to render without request context.
  public init(
    environment: BuildEnvironment = .production,
    cssOutputMode: CSSOutputMode = .production,
    viewTransitions: ViewTransitionNavigation = .enabled,
    runtimeArtifacts: [BuildArtifact] = [],
    assets: [BuildAsset] = [],
    remoteAssets: [RemoteAsset] = [],
    assetToolchain: AssetToolchain = .init(),
    cdnBaseURL: URL? = nil,
    speculationRules: [SpeculationRule] = [],
    deploymentRoutes: [DeploymentRoute] = [],
    routingManifestEncoder: (any RoutingManifestEncoder)? = nil,
    artifactLayout: ArtifactLayout = .init(),
    runtimes: [DeploymentRuntime] = [],
    prerenderedPagePaths: Set<String> = []
  ) {
    self.environment = environment
    self.cssOutputMode = cssOutputMode
    self.viewTransitions = viewTransitions
    self.runtimeArtifacts = runtimeArtifacts
    self.assets = assets
    self.remoteAssets = remoteAssets
    self.assetToolchain = assetToolchain
    self.cdnBaseURL = cdnBaseURL
    self.speculationRules = speculationRules
    self.deploymentRoutes = deploymentRoutes
    self.routingManifestEncoder = routingManifestEncoder
    self.artifactLayout = artifactLayout
    self.runtimes = runtimes
    self.prerenderedPagePaths = prerenderedPagePaths
  }
}
