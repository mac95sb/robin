import Foundation
import RobinContent
import RobinCore
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle

/// Builds deterministic artifacts from a resolved Robin application.
public struct BuildPipeline {
  /// Builds and materializes an application beneath `.robin`.
  ///
  /// The application's registered pages and controllers determine its mode. Configuration can
  /// provide native or WebAssembly runtime artifacts for API and SSR output, but cannot override
  /// that inference.
  ///
  /// - Parameters:
  ///   - application: The application to build.
  ///   - configuration: Output settings and compiled runtime artifacts.
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
    let runtimeArtifacts = configuration.runtimeArtifacts
    switch mode {
    case .static where !runtimeArtifacts.isEmpty:
      throw BuildError.staticApplicationHasRuntimeArtifacts
    case .api, .ssr:
      guard
        runtimeArtifacts.contains(where: {
          $0.kind == .executable || $0.kind == .functionBundle
            || $0.kind == .webAssembly
        })
      else {
        throw BuildError.missingRuntimeArtifact(mode)
      }
    default: break
    }
    try validate(configuration.runtimes, artifacts: runtimeArtifacts, mode: mode)

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
    var artifacts = runtimeArtifacts + assets.artifacts
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
          case .webAssembly(let path):
            .webAssembly(
              configuration.artifactLayout.path(for: path, kind: .webAssembly))
          }
        return try DeploymentRoute(
          pattern: route.pattern, destination: destination, precedence: route.precedence)
      }.sorted {
        ($0.precedence, $0.pattern) < ($1.precedence, $1.pattern)
      }
      artifacts.append(try routingManifestEncoder.encode(routes))
    }
    var runtimes: [DeploymentRuntime] = []
    for runtime in configuration.runtimes {
      guard let artifact = runtimeArtifacts.first(where: { $0.path == runtime.artifact }) else {
        throw BuildError.invalidRuntimeArtifact(runtime.artifact)
      }
      let adapter = runtime.hostAdapter.flatMap { path in
        runtimeArtifacts.first { $0.path == path }
      }
      runtimes.append(
        try runtime.replacingArtifacts(
          artifact: configuration.artifactLayout.path(for: runtime.artifact, kind: artifact.kind),
          hostAdapter: adapter.map {
            configuration.artifactLayout.path(for: $0.path, kind: $0.kind)
          }
        ))
    }
    artifacts.append(try deploymentMetadata(mode: mode, runtimes: runtimes))
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
    let stylesheetOutput = try stylesheetArtifacts(
      for: roots,
      theme: theme,
      mode: configuration.cssOutputMode,
      viewTransitions: mode == .ssr ? configuration.viewTransitions : .disabled,
      cdnBaseURL: configuration.cdnBaseURL
    )
    let styles = stylesheetOutput.styles
    var artifacts = stylesheetOutput.artifacts
    let sharedDependencies = speculation.artifact.map { [$0.path] } ?? []

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
      scriptReference = ResourceReference(
        path: path, bytes: bytes, cdnBaseURL: configuration.cdnBaseURL)
    }

    var outputPaths: Set<String> = []
    for (pageIndex, ((page, originalRoot), root)) in zip(zip(pages, originalRoots), roots)
      .enumerated()
    where mode == .static || configuration.prerenderedPagePaths.contains(page.path) {
      let contentDiagnostics = ContentReferenceValidator(
        routes: registeredPaths,
        assets: Set(assets.references.keys)
      ).validate(contentReferences(in: originalRoot, assets: assets.references), from: page.path)
      if let diagnostic = contentDiagnostics.first {
        switch diagnostic {
        case .brokenLink(let destination), .invalidReference(let destination):
          throw BuildError.unknownPageReference(destination)
        case .missingAsset(let destination):
          throw BuildError.unknownAssetReference(destination)
        default: break
        }
      }
      let outputPath = try staticOutputPath(for: page.path)
      guard outputPaths.insert(outputPath).inserted else {
        throw BuildError.duplicatePagePath(page.path)
      }
      let body = try HTMLRenderer.render(root, styles: styles.className(for:))
      var metadata = application.metadata.merging(page: page.metadata)
      var schemas: Set<String> = []
      for data in metadata.structuredData where !schemas.insert(data.schemaName).inserted {
        throw BuildError.duplicateStructuredData(data.schemaName)
      }
      var referencedAssets = Set(
        referencedAssetPaths(in: originalRoot, references: assets.references))
      metadata = try processedMetadata(
        metadata, assets: assets.references, referencedAssets: &referencedAssets)
      let document = try document(
        body: body,
        metadata: metadata,
        stylesheets: stylesheetOutput.referencesByPage[pageIndex],
        script: scriptReference,
        additionalHeadElements: assets.headElements + [speculation.headElement].compactMap { $0 }
      )
      artifacts.append(
        try BuildArtifact(
          kind: .staticFile,
          path: outputPath,
          bytes: Array(document.utf8),
          dependencies: sharedDependencies
            + stylesheetOutput.referencesByPage[pageIndex].map(\.path)
            + [scriptReference?.path].compactMap { $0 }
            + referencedAssets.sorted()
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
    stylesheets: [ResourceReference],
    script: ResourceReference?,
    additionalHeadElements: [String]
  ) throws -> String {
    let language = HTMLRenderer.escape(metadata.language ?? "en")
    let direction = LocalizationFormatter(locale: metadata.language ?? "en").direction.rawValue
    var head =
      "<meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    if let title = metadata.composedTitle {
      head += "<title>\(HTMLRenderer.escape(title))</title>"
    }
    if let description = metadata.description {
      head += "<meta name=\"description\" content=\"\(HTMLRenderer.escape(description))\">"
    }
    if let canonicalURL = metadata.canonicalURL {
      head += "<link rel=\"canonical\" href=\"\(HTMLRenderer.escape(canonicalURL))\">"
      head += "<meta property=\"og:url\" content=\"\(HTMLRenderer.escape(canonicalURL))\">"
    }
    let openGraphType =
      metadata.openGraphType
      ?? (metadata.structuredData.contains { $0.schemaName == "Article" } ? .article : .website)
    head += "<meta property=\"og:type\" content=\"\(openGraphType.rawValue)\">"
    if let site = metadata.site {
      head += "<meta property=\"og:site_name\" content=\"\(HTMLRenderer.escape(site))\">"
    }
    if let title = metadata.openGraph?.title ?? metadata.composedTitle {
      head += "<meta property=\"og:title\" content=\"\(HTMLRenderer.escape(title))\">"
    }
    if let description = metadata.openGraph?.description ?? metadata.description {
      head += "<meta property=\"og:description\" content=\"\(HTMLRenderer.escape(description))\">"
    }
    if let locale = metadata.language {
      head += "<meta property=\"og:locale\" content=\"\(HTMLRenderer.escape(locale))\">"
    }
    for alternate in metadata.alternateLanguages.sorted(by: { $0.language < $1.language }) {
      head +=
        "<meta property=\"og:locale:alternate\" content=\"\(HTMLRenderer.escape(alternate.language))\">"
    }
    if let author = metadata.author {
      head += "<meta name=\"author\" content=\"\(HTMLRenderer.escape(author.name))\">"
      head +=
        "<meta property=\"article:author\" content=\"\(HTMLRenderer.escape(author.url ?? author.name))\">"
    }
    if let publisher = metadata.publisher {
      head +=
        "<meta property=\"article:publisher\" content=\"\(HTMLRenderer.escape(publisher.url ?? publisher.name))\">"
    }
    let dateFormatter = ISO8601DateFormatter()
    if let publishedAt = metadata.publishedAt {
      head +=
        "<meta property=\"article:published_time\" content=\"\(dateFormatter.string(from: publishedAt))\">"
    }
    if let modifiedAt = metadata.modifiedAt {
      head +=
        "<meta property=\"article:modified_time\" content=\"\(dateFormatter.string(from: modifiedAt))\">"
    }
    if let image = metadata.openGraph?.image ?? metadata.image {
      head +=
        "<meta property=\"og:image\" content=\"\(HTMLRenderer.escape(image.url))\"><meta property=\"og:image:alt\" content=\"\(HTMLRenderer.escape(image.alternativeText))\">"
      if let width = image.width {
        head += "<meta property=\"og:image:width\" content=\"\(width)\">"
      }
      if let height = image.height {
        head += "<meta property=\"og:image:height\" content=\"\(height)\">"
      }
      if let mediaType = image.mediaType {
        head += "<meta property=\"og:image:type\" content=\"\(HTMLRenderer.escape(mediaType))\">"
      }
    }
    let xImage = metadata.xCard?.image ?? metadata.image
    if metadata.xCard?.title != nil || metadata.composedTitle != nil
      || metadata.xCard?.description != nil || metadata.description != nil
    {
      head +=
        "<meta name=\"twitter:card\" content=\"\((metadata.xCardType ?? (xImage == nil ? .summary : .summaryLargeImage)).rawValue)\">"
    }
    if let title = metadata.xCard?.title ?? metadata.composedTitle {
      head += "<meta name=\"twitter:title\" content=\"\(HTMLRenderer.escape(title))\">"
    }
    if let description = metadata.xCard?.description ?? metadata.description {
      head += "<meta name=\"twitter:description\" content=\"\(HTMLRenderer.escape(description))\">"
    }
    if let image = xImage {
      head +=
        "<meta name=\"twitter:image\" content=\"\(HTMLRenderer.escape(image.url))\"><meta name=\"twitter:image:alt\" content=\"\(HTMLRenderer.escape(image.alternativeText))\">"
    }
    if let robots = metadata.robots {
      head += "<meta name=\"robots\" content=\"\(robots.content)\">"
    }
    for alternate in metadata.alternateLanguages.sorted(by: { $0.language < $1.language }) {
      head +=
        "<link rel=\"alternate\" hreflang=\"\(HTMLRenderer.escape(alternate.language))\" href=\"\(HTMLRenderer.escape(alternate.url))\">"
    }
    for icon in metadata.icons {
      let sizes = icon.sizes.map { " sizes=\"\(HTMLRenderer.escape($0))\"" } ?? ""
      let type = icon.mediaType.map { " type=\"\(HTMLRenderer.escape($0))\"" } ?? ""
      head += "<link rel=\"icon\" href=\"\(HTMLRenderer.escape(icon.url))\"\(sizes)\(type)>"
    }
    if let manifestURL = metadata.manifestURL {
      head += "<link rel=\"manifest\" href=\"\(HTMLRenderer.escape(manifestURL))\">"
    }
    for data in metadata.structuredData {
      head += "<script type=\"application/ld+json\">\(try data.jsonLD(metadata: metadata))</script>"
    }
    for stylesheet in stylesheets {
      let crossorigin = stylesheet.crossOrigin ? " crossorigin=\"anonymous\"" : ""
      head +=
        "<link rel=\"stylesheet\" data-robin-style href=\"\(HTMLRenderer.escape(stylesheet.browserURL))\" integrity=\"\(stylesheet.integrity)\"\(crossorigin)>"
    }
    if let script {
      let crossorigin = script.crossOrigin ? " crossorigin=\"anonymous\"" : ""
      head +=
        "<script type=\"module\" src=\"\(HTMLRenderer.escape(script.browserURL))\" integrity=\"\(script.integrity)\"\(crossorigin)></script>"
    }
    head += additionalHeadElements.joined()
    return
      "<!doctype html><html lang=\"\(language)\" dir=\"\(direction)\"><head>\(head)</head><body>\(body)</body></html>"
  }

  private static func stylesheetArtifacts(
    for roots: [RenderNode],
    theme: Theme,
    mode: CSSOutputMode,
    viewTransitions: ViewTransitionNavigation,
    cdnBaseURL: URL?
  ) throws -> (
    styles: CompiledStyles,
    artifacts: [BuildArtifact],
    referencesByPage: [[ResourceReference]]
  ) {
    let styles = try StyleCompiler.compile(
      .fragment(roots), theme: theme, mode: mode, viewTransitions: .disabled)
    var signatureByClass: [String: [StyleDeclaration]] = [:]
    var pagesByClass: [String: Set<Int>] = [:]
    for (pageIndex, root) in roots.enumerated() {
      for signature in styleSignatures(in: root) {
        guard let className = styles.className(for: signature) else { continue }
        signatureByClass[className] = signature
        pagesByClass[className, default: []].insert(pageIndex)
      }
    }

    let everyPage = Array(roots.indices)
    var classesByPages: [[Int]: [String]] = [:]
    for (className, pages) in pagesByClass {
      classesByPages[pages.sorted(), default: []].append(className)
    }
    if viewTransitions == .enabled, classesByPages[everyPage] == nil {
      classesByPages[everyPage] = []
    }

    var artifacts: [BuildArtifact] = []
    var referencesByPage = Array(repeating: [ResourceReference](), count: roots.count)
    for pageIndexes in classesByPages.keys.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
      let signatures = classesByPages[pageIndexes, default: []].sorted().compactMap {
        signatureByClass[$0]
      }
      let compiled = try StyleCompiler.compile(
        signatures: signatures,
        theme: theme,
        mode: mode,
        viewTransitions: pageIndexes == everyPage ? viewTransitions : .disabled
      )
      guard !compiled.css.isEmpty else { continue }
      let bytes = Array(compiled.css.utf8)
      let path = "assets/\(ContentDigest.sha256(bytes).prefix(12)).css"
      let artifact = try BuildArtifact(
        kind: .staticFile,
        path: path,
        bytes: bytes,
        mediaType: "text/css",
        integrity: ContentDigest.sha384Integrity(bytes)
      )
      let reference = ResourceReference(path: path, bytes: bytes, cdnBaseURL: cdnBaseURL)
      artifacts.append(artifact)
      for pageIndex in pageIndexes { referencesByPage[pageIndex].append(reference) }
    }
    for syntaxTheme in SyntaxHighlightTheme.allCases {
      let pageIndexes = roots.indices.filter { syntaxThemes(in: roots[$0]).contains(syntaxTheme) }
      guard !pageIndexes.isEmpty else { continue }
      let bytes = Array(syntaxTheme.stylesheet.utf8)
      let path = "assets/\(ContentDigest.sha256(bytes).prefix(12)).css"
      let artifact = try BuildArtifact(
        kind: .staticFile,
        path: path,
        bytes: bytes,
        mediaType: "text/css",
        integrity: ContentDigest.sha384Integrity(bytes)
      )
      let reference = ResourceReference(path: path, bytes: bytes, cdnBaseURL: cdnBaseURL)
      artifacts.append(artifact)
      for pageIndex in pageIndexes { referencesByPage[pageIndex].append(reference) }
    }
    return (styles, artifacts, referencesByPage)
  }

  private static func styleSignatures(in node: RenderNode) -> [[StyleDeclaration]] {
    switch node.renderingStorage {
    case .text: []
    case .fragment(let children): children.flatMap(styleSignatures)
    case .element(let element):
      (element.styles.isEmpty ? [] : [element.styles]) + element.children.flatMap(styleSignatures)
    }
  }

  private static func syntaxThemes(in node: RenderNode) -> Set<SyntaxHighlightTheme> {
    switch node.renderingStorage {
    case .text: []
    case .fragment(let children):
      children.reduce(into: Set<SyntaxHighlightTheme>()) {
        $0.formUnion(syntaxThemes(in: $1))
      }
    case .element(let element):
      element.attributes.reduce(into: Set<SyntaxHighlightTheme>()) { themes, attribute in
        if case .syntaxTheme(let theme) = attribute { themes.insert(theme) }
      }.union(
        element.children.reduce(into: Set<SyntaxHighlightTheme>()) {
          $0.formUnion(syntaxThemes(in: $1))
        })
    }
  }

  private static func deploymentMetadata(
    mode: ApplicationMode,
    runtimes: [DeploymentRuntime]
  ) throws -> BuildArtifact {
    struct Deployment: Encodable {
      let mode: String
      let runtimes: [DeploymentRuntime]?
    }
    let modeName =
      switch mode {
      case .static: "static"
      case .api: "api"
      case .ssr: "ssr"
      }
    let runtimes = runtimes.sorted {
      ($0.interface.rawValue, $0.artifact) < ($1.interface.rawValue, $1.artifact)
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try BuildArtifact(
      kind: .deploymentMetadata,
      path: "deployment.json",
      bytes: Array(
        try encoder.encode(Deployment(mode: modeName, runtimes: runtimes.isEmpty ? nil : runtimes))),
      dependencies: runtimes.flatMap { [$0.artifact] + [$0.hostAdapter].compactMap { $0 } }
    )
  }

  private static func validate(
    _ runtimes: [DeploymentRuntime],
    artifacts: [BuildArtifact],
    mode: ApplicationMode
  ) throws {
    guard mode != .static || runtimes.isEmpty else {
      throw BuildError.staticApplicationHasRuntimeArtifacts
    }
    for runtime in runtimes {
      guard let artifact = artifacts.first(where: { $0.path == runtime.artifact }) else {
        throw BuildError.invalidRuntimeArtifact(runtime.artifact)
      }
      if let maximumBytes = runtime.maximumArtifactBytes,
        artifact.bytes.count > maximumBytes
      {
        throw BuildError.runtimeArtifactTooLarge(
          artifact: artifact.path,
          maximumBytes: maximumBytes,
          actualBytes: artifact.bytes.count
        )
      }
      if let adapter = runtime.hostAdapter,
        artifacts.first(where: { $0.path == adapter && $0.kind == .hostAdapter }) == nil
      {
        throw BuildError.invalidRuntimeArtifact(adapter)
      }
      let valid =
        switch runtime.interface {
        case .persistentHTTP: artifact.kind == .executable
        case .lambda: artifact.kind == .functionBundle || artifact.kind == .executable
        case .wasiHTTP, .webAssembly: artifact.kind == .webAssembly
        }
      guard valid else { throw BuildError.invalidRuntimeArtifact(runtime.artifact) }
    }
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

  private static func processedMetadata(
    _ source: Metadata,
    assets: [String: ProcessedAssets.Reference],
    referencedAssets: inout Set<String>
  ) throws -> Metadata {
    var metadata = source
    for value in [metadata.canonicalURL, metadata.author?.url, metadata.publisher?.url]
      .compactMap({ $0 })
    {
      try validateMetadataURL(value)
    }
    for alternate in metadata.alternateLanguages { try validateMetadataURL(alternate.url) }

    metadata.image = try metadata.image.map {
      try processedMetadataImage($0, assets: assets, referencedAssets: &referencedAssets)
    }
    if let social = metadata.openGraph {
      metadata.openGraph = .init(
        title: social.title,
        description: social.description,
        image: try social.image.map {
          try processedMetadataImage($0, assets: assets, referencedAssets: &referencedAssets)
        })
    }
    if let social = metadata.xCard {
      metadata.xCard = .init(
        title: social.title,
        description: social.description,
        image: try social.image.map {
          try processedMetadataImage($0, assets: assets, referencedAssets: &referencedAssets)
        })
    }
    metadata.icons = try metadata.icons.map { icon in
      Metadata.Icon(
        url: try processedMetadataResource(
          icon.url, assets: assets, referencedAssets: &referencedAssets),
        sizes: icon.sizes,
        mediaType: icon.mediaType)
    }
    metadata.manifestURL = try metadata.manifestURL.map {
      try processedMetadataResource($0, assets: assets, referencedAssets: &referencedAssets)
    }
    return metadata
  }

  private static func processedMetadataImage(
    _ image: Metadata.Image,
    assets: [String: ProcessedAssets.Reference],
    referencedAssets: inout Set<String>
  ) throws -> Metadata.Image {
    guard let reference = assets[image.url] else {
      if image.url.hasPrefix("/") { throw BuildError.unknownAssetReference(image.url) }
      try validateMetadataURL(image.url)
      return image
    }
    referencedAssets.insert(reference.artifact.path)
    return Metadata.Image(
      url: reference.browserURL,
      alternativeText: image.alternativeText,
      width: image.width ?? reference.artifact.imageMetadata?.width,
      height: image.height ?? reference.artifact.imageMetadata?.height,
      mediaType: image.mediaType ?? reference.artifact.mediaType)
  }

  private static func processedMetadataResource(
    _ value: String,
    assets: [String: ProcessedAssets.Reference],
    referencedAssets: inout Set<String>
  ) throws -> String {
    if let reference = assets[value] {
      referencedAssets.insert(reference.artifact.path)
      return reference.browserURL
    }
    if value.hasPrefix("/") { throw BuildError.unknownAssetReference(value) }
    try validateMetadataURL(value)
    return value
  }

  private static func validateMetadataURL(_ value: String) throws {
    guard let components = URLComponents(string: value),
      components.scheme == "https" || components.scheme == "http",
      components.host != nil,
      components.user == nil,
      components.password == nil
    else { throw BuildError.invalidMetadataURL(value) }
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
          references[value].map { [$0.artifact.path] } ?? []
        case .sourceSet(let candidates):
          candidates.compactMap { references[$0.source]?.artifact.path }
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

  private static func contentReferences(
    in node: RenderNode,
    assets: [String: ProcessedAssets.Reference]
  ) -> [ContentReference] {
    switch node.renderingStorage {
    case .text: return []
    case .fragment(let children):
      return children.flatMap { contentReferences(in: $0, assets: assets) }
    case .element(let element):
      let direct = element.attributes.flatMap { attribute -> [ContentReference] in
        switch attribute {
        case .source(let value): return [.asset(value)]
        case .sourceSet(let candidates): return candidates.map { .asset($0.source) }
        case .href(let value): return [assets[value] == nil ? .link(value) : .asset(value)]
        default: return []
        }
      }
      return direct + element.children.flatMap { contentReferences(in: $0, assets: assets) }
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
