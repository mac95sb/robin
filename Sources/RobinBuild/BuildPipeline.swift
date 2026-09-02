import Foundation
import RobinCore
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle

/// Builds deterministic artifacts from a resolved Robin application.
public enum BuildPipeline {
  /// Builds and materializes an application beneath `.robin`.
  ///
  /// The application's registered pages and controllers determine its mode. Configuration can
  /// provide executable bytes for API and SSR output, but cannot override that inference.
  ///
  /// - Parameters:
  ///   - application: The application to build.
  ///   - configuration: Output settings and compiled executable artifacts.
  ///   - layout: The project's validated output layout.
  /// - Returns: The inferred mode and deterministic manifest.
  /// - Throws: ``BuildError`` or an error from rendering, style compilation, or file access.
  @discardableResult
  public static func build<Application: App>(
    _ application: Application,
    configuration: BuildConfiguration = .init(),
    in layout: OutputLayout
  ) throws -> BuildResult {
    guard configuration.remoteAssets.isEmpty else {
      throw BuildError.remoteAssetsRequireAsyncBuild
    }
    return try buildResolved(application, configuration: configuration, in: layout)
  }

  /// Downloads remote assets, then builds and materializes an application beneath `.robin`.
  ///
  /// Remote assets are fetched only by this build-time operation. Production builds require a
  /// pinned digest for each remote source.
  ///
  /// - Parameters:
  ///   - application: The application to build.
  ///   - configuration: Output settings and local or remote assets.
  ///   - layout: The project's validated output layout.
  /// - Returns: The inferred mode and deterministic manifest.
  /// - Throws: ``BuildError`` or an error from rendering, transforms, or file access.
  @discardableResult
  public static func build<Application: App>(
    _ application: Application,
    configuration: BuildConfiguration,
    in layout: OutputLayout
  ) async throws -> BuildResult {
    var resolved = configuration
    // ponytail: downloads are serialized; use a bounded task group when measurements justify it.
    for remote in configuration.remoteAssets {
      resolved.assets.append(
        try await remote.resolve(environment: configuration.environment, layout: layout))
    }
    resolved.remoteAssets = []
    return try buildResolved(application, configuration: resolved, in: layout)
  }

  private static func buildResolved<Application: App>(
    _ application: Application,
    configuration: BuildConfiguration,
    in layout: OutputLayout
  ) throws -> BuildResult {
    if let cdnBaseURL = configuration.cdnBaseURL,
      cdnBaseURL.scheme != "https" || cdnBaseURL.host == nil || cdnBaseURL.user != nil
        || cdnBaseURL.password != nil || cdnBaseURL.query != nil || cdnBaseURL.fragment != nil
    {
      throw BuildError.invalidCDNBaseURL(cdnBaseURL.absoluteString)
    }
    let mode = try application.mode
    let executableArtifacts = configuration.executableArtifacts
    switch mode {
    case .static where !executableArtifacts.isEmpty:
      throw BuildError.staticApplicationHasExecutableArtifacts
    case .api, .ssr:
      guard
        executableArtifacts.contains(where: {
          $0.kind == .executable || $0.kind == .functionBundle
        })
      else {
        throw BuildError.missingExecutableArtifact(mode)
      }
    default: break
    }

    let assets = try AssetProcessor.process(
      configuration.assets,
      toolchain: configuration.assetToolchain,
      cdnBaseURL: configuration.cdnBaseURL,
      layout: layout
    )
    let speculation = try SpeculationRulesCompiler.compile(
      mode == .api ? [] : configuration.speculationRules,
      pagePaths: Set(application.pages.pages.map(\.path)),
      assets: assets
    )
    var artifacts = executableArtifacts + assets.artifacts
    if let artifact = speculation.artifact { artifacts.append(artifact) }
    if mode != .api {
      artifacts += try pageArtifacts(
        application,
        mode: mode,
        configuration: configuration,
        assets: assets,
        speculation: speculation
      )
    }
    if let routingManifestEncoder = configuration.routingManifestEncoder {
      let routes = try configuration.deploymentRoutes.map { route in
        let destination: DeploymentRoute.Destination =
          switch route.destination {
          case .staticFile(let path):
            .staticFile(configuration.artifactLayout.path(for: path, kind: .staticFile))
          case .functionBundle(let path):
            .functionBundle(configuration.artifactLayout.path(for: path, kind: .functionBundle))
          }
        return try DeploymentRoute(
          pattern: route.pattern, destination: destination, precedence: route.precedence)
      }.sorted {
        ($0.precedence, $0.pattern) < ($1.precedence, $1.pattern)
      }
      artifacts.append(try routingManifestEncoder.encode(routes))
    }
    artifacts.append(try deploymentMetadata(mode: mode))
    let manifest = try ArtifactGraph(configuration.artifactLayout.apply(to: artifacts))
      .materialize(in: layout)
    return BuildResult(mode: mode, manifest: manifest)
  }

  private static func pageArtifacts<Application: App>(
    _ application: Application,
    mode: ApplicationMode,
    configuration: BuildConfiguration,
    assets: ProcessedAssets,
    speculation: CompiledSpeculationRules
  ) throws -> [BuildArtifact] {
    let pages = application.pages.pages
    let registeredPaths = Set(pages.map(\.path))
    if let unknown = configuration.prerenderedPagePaths.first(where: {
      !registeredPaths.contains($0)
    }) {
      throw BuildError.unknownPrerenderedPage(unknown)
    }
    let originalRoots = pages.map { RenderNode.fragment($0.body.nodes) }
    let roots = originalRoots.map { replacingAssetReferences(in: $0, with: assets.references) }
    let theme: Theme
    if let configured = application.theme as? Theme {
      theme = configured
    } else if application.theme is DefaultApplicationTheme {
      theme = .default
    } else {
      throw BuildError.unsupportedTheme
    }
    let combined = RenderNode.fragment(roots)
    let styles = try StyleCompiler.compile(
      combined,
      theme: theme,
      mode: configuration.cssOutputMode,
      viewTransitions: mode == .ssr ? configuration.viewTransitions : .disabled
    )

    var artifacts: [BuildArtifact] = []
    var dependencies = speculation.artifact.map { [$0.path] } ?? []
    var stylesheetReference: ResourceReference?
    if !styles.css.isEmpty {
      let bytes = Array(styles.css.utf8)
      let path = fingerprintedPath(name: "robin", extension: "css", bytes: bytes)
      artifacts.append(
        try BuildArtifact(
          kind: .staticFile,
          path: path,
          bytes: bytes,
          mediaType: "text/css",
          integrity: ContentDigest.sha384Integrity(bytes)
        ))
      dependencies.append(path)
      stylesheetReference = ResourceReference(
        path: path, bytes: bytes, cdnBaseURL: configuration.cdnBaseURL)
    }

    var scriptReference: ResourceReference?
    if let module = try application.clientNavigationRuntime {
      let bytes = Array(module.utf8)
      let path = fingerprintedPath(name: "navigation", extension: "js", bytes: bytes)
      artifacts.append(
        try BuildArtifact(
          kind: .staticFile,
          path: path,
          bytes: bytes,
          mediaType: "text/javascript",
          integrity: ContentDigest.sha384Integrity(bytes),
          scriptOrigin: .robinDirectCapability(.navigation, selectedBy: "App.clientNavigation")
        ))
      dependencies.append(path)
      scriptReference = ResourceReference(
        path: path, bytes: bytes, cdnBaseURL: configuration.cdnBaseURL)
    }

    var outputPaths: Set<String> = []
    for ((page, originalRoot), root) in zip(zip(pages, originalRoots), roots)
    where mode == .static || configuration.prerenderedPagePaths.contains(page.path) {
      let outputPath = try staticOutputPath(for: page.path)
      guard outputPaths.insert(outputPath).inserted else {
        throw BuildError.duplicatePagePath(page.path)
      }
      let body = try HTMLRenderer.render(root, styles: styles.className(for:))
      var metadata = application.metadata.merging(page: page.metadata)
      var referencedAssets = referencedAssetPaths(in: originalRoot, references: assets.references)
      if let image = metadata.image, let reference = assets.references[image.url] {
        metadata.image = .init(url: reference.browserURL, alternativeText: image.alternativeText)
        referencedAssets.append(reference.outputPath)
      }
      let document = document(
        body: body,
        metadata: metadata,
        stylesheet: stylesheetReference,
        script: scriptReference,
        additionalHeadElements: assets.headElements + [speculation.headElement].compactMap { $0 }
      )
      artifacts.append(
        try BuildArtifact(
          kind: .staticFile,
          path: outputPath,
          bytes: Array(document.utf8),
          dependencies: dependencies + Array(Set(referencedAssets)).sorted()
        ))
    }
    return artifacts
  }

  private static func staticOutputPath(for route: String) throws -> String {
    guard route.first == "/", !route.contains("?"), !route.contains("#"),
      !route.contains("\\")
    else { throw BuildError.invalidPagePath(route) }
    let components = route.split(separator: "/", omittingEmptySubsequences: false)
    guard
      components.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        || route == "/"
    else { throw BuildError.invalidPagePath(route) }
    if route == "/" { return "index.html" }
    return route.dropFirst() + "/index.html"
  }

  private static func fingerprintedPath(name: String, extension suffix: String, bytes: [UInt8])
    -> String
  {
    "assets/\(name)-\(ContentDigest.sha256(bytes).prefix(12)).\(suffix)"
  }

  private static func document(
    body: String,
    metadata: Metadata,
    stylesheet: ResourceReference?,
    script: ResourceReference?,
    additionalHeadElements: [String]
  ) -> String {
    let language = HTMLRenderer.escape(metadata.language ?? "en")
    var head =
      "<meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    if let title = metadata.title {
      head += "<title>\(HTMLRenderer.escape(title))</title>"
    }
    if let description = metadata.description {
      head += "<meta name=\"description\" content=\"\(HTMLRenderer.escape(description))\">"
    }
    if let canonicalURL = metadata.canonicalURL {
      head += "<link rel=\"canonical\" href=\"\(HTMLRenderer.escape(canonicalURL))\">"
    }
    if let image = metadata.image {
      head +=
        "<meta property=\"og:image\" content=\"\(HTMLRenderer.escape(image.url))\"><meta property=\"og:image:alt\" content=\"\(HTMLRenderer.escape(image.alternativeText))\">"
    }
    if let stylesheet {
      let crossorigin = stylesheet.crossOrigin ? " crossorigin=\"anonymous\"" : ""
      head +=
        "<link rel=\"stylesheet\" href=\"\(HTMLRenderer.escape(stylesheet.browserURL))\" integrity=\"\(stylesheet.integrity)\"\(crossorigin)>"
    }
    if let script {
      let crossorigin = script.crossOrigin ? " crossorigin=\"anonymous\"" : ""
      head +=
        "<script type=\"module\" src=\"\(HTMLRenderer.escape(script.browserURL))\" integrity=\"\(script.integrity)\"\(crossorigin)></script>"
    }
    head += additionalHeadElements.joined()
    return
      "<!doctype html><html lang=\"\(language)\"><head>\(head)</head><body>\(body)</body></html>"
  }

  private static func deploymentMetadata(mode: ApplicationMode) throws -> BuildArtifact {
    struct Deployment: Encodable { let mode: String }
    let modeName =
      switch mode {
      case .static: "static"
      case .api: "api"
      case .ssr: "ssr"
      }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try BuildArtifact(
      kind: .deploymentMetadata,
      path: "deployment.json",
      bytes: Array(try encoder.encode(Deployment(mode: modeName)))
    )
  }

  private static func replacingAssetReferences(
    in node: RenderNode,
    with references: [String: ProcessedAssets.Reference]
  ) -> RenderNode {
    switch node.renderingStorage {
    case .text: node
    case .fragment(let children):
      .fragment(children.map { replacingAssetReferences(in: $0, with: references) })
    case .element(let element):
      .element(
        .init(
          kind: element.kind,
          attributes: element.attributes.map { attribute in
            switch attribute {
            case .source(let value):
              references[value].map { .source($0.browserURL) } ?? attribute
            case .sourceSet(let candidates):
              .sourceSet(
                candidates.map { candidate in
                  .init(
                    source: references[candidate.source]?.browserURL ?? candidate.source,
                    width: candidate.width
                  )
                })
            case .href(let value): references[value].map { .href($0.browserURL) } ?? attribute
            default: attribute
            }
          },
          styles: element.styles,
          children: element.children.map {
            replacingAssetReferences(in: $0, with: references)
          }
        ))
    }
  }

  private static func referencedAssetPaths(
    in node: RenderNode,
    references: [String: ProcessedAssets.Reference]
  ) -> [String] {
    switch node.renderingStorage {
    case .text: return []
    case .fragment(let children):
      return Array(Set(children.flatMap { referencedAssetPaths(in: $0, references: references) }))
        .sorted()
    case .element(let element):
      let direct = element.attributes.flatMap { attribute -> [String] in
        switch attribute {
        case .source(let value), .href(let value):
          references[value].map { [$0.outputPath] } ?? []
        case .sourceSet(let candidates):
          candidates.compactMap { references[$0.source]?.outputPath }
        default: []
        }
      }
      return Array(
        Set(
          direct
            + element.children.flatMap {
              referencedAssetPaths(in: $0, references: references)
            })
      )
      .sorted()
    }
  }
}

private struct ResourceReference {
  let path: String
  let browserURL: String
  let integrity: String
  let crossOrigin: Bool

  init(path: String, bytes: [UInt8], cdnBaseURL: URL?) {
    self.path = path
    self.browserURL =
      cdnBaseURL.map { $0.appendingPathComponent(path).absoluteString } ?? "/\(path)"
    self.integrity = ContentDigest.sha384Integrity(bytes)
    self.crossOrigin = cdnBaseURL != nil
  }
}
