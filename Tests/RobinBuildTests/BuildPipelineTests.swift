import Crypto
import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinStyle
import Testing

@Suite("Application build pipeline")
struct BuildPipelineTests {
  @Test func buildsStaticPagesWithFingerprintingAndNoDefaultJavaScript() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let result = try BuildPipeline.build(StaticApplication(), in: OutputLayout(projectRoot: root))

    #expect(result.mode == .static)
    #expect(result.manifest.artifacts.map(\.path).contains("index.html"))
    #expect(result.manifest.artifacts.map(\.path).contains("about/index.html"))
    #expect(!result.manifest.artifacts.map(\.path).contains { $0.hasSuffix(".js") })
    let html = try String(
      contentsOf: root.appendingPathComponent(".robin/build/index.html"), encoding: .utf8)
    #expect(html.contains("<!doctype html><html lang=\"en-GB\" dir=\"ltr\">"))
    #expect(html.contains("<title>Home | Robin</title>"))
    #expect(html.contains("property=\"og:title\" content=\"Robin on Open Graph\""))
    #expect(html.contains("property=\"og:type\" content=\"website\""))
    #expect(html.contains("property=\"og:site_name\" content=\"Robin\""))
    #expect(html.contains("property=\"og:locale:alternate\" content=\"fr\""))
    #expect(html.contains("name=\"twitter:description\" content=\"Robin on X\""))
    #expect(html.contains("name=\"robots\" content=\"index,nofollow\""))
    #expect(html.contains("rel=\"alternate\" hreflang=\"fr\""))
    #expect(html.contains("rel=\"icon\" href=\"https://example.com/icon.svg\" sizes=\"any\""))
    #expect(html.contains("rel=\"manifest\" href=\"https://example.com/site.webmanifest\""))
    #expect(html.contains("type=\"application/ld+json\""))
    #expect(html.contains("\"@type\":\"SoftwareApplication\""))
    #expect(html.contains("\"operatingSystem\":\"Linux and macOS\""))
    #expect(html.contains("integrity=\"sha384-"))
    let about = try String(
      contentsOf: root.appendingPathComponent(".robin/build/about/index.html"), encoding: .utf8)
    #expect(html.components(separatedBy: "data-robin-style").count == 3)
    #expect(about.components(separatedBy: "data-robin-style").count == 2)
    let stylesheets = result.manifest.artifacts.filter { $0.mediaType == "text/css" }
    #expect(stylesheets.count == 2)
    #expect(stylesheets.allSatisfy { !$0.path.contains("home") && !$0.path.contains("about") })
  }

  @Test func validatesModeSpecificRuntimeArtifacts() throws {
    let executable = try BuildArtifact(kind: .functionBundle, path: "server", bytes: [1])
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(throws: BuildError.staticApplicationHasRuntimeArtifacts) {
      try BuildPipeline.build(
        StaticApplication(),
        configuration: .init(runtimeArtifacts: [executable]),
        in: OutputLayout(projectRoot: root)
      )
    }
    #expect(throws: BuildError.missingRuntimeArtifact(.api)) {
      try BuildPipeline.build(APIApplication(), in: OutputLayout(projectRoot: root))
    }
    #expect(throws: BuildError.duplicateArtifactPath("server")) {
      try BuildPipeline.build(
        APIApplication(),
        configuration: .init(runtimeArtifacts: [executable, executable]),
        in: OutputLayout(projectRoot: root)
      )
    }
    let result = try BuildPipeline.build(
      APIApplication(),
      configuration: .init(runtimeArtifacts: [executable]),
      in: OutputLayout(projectRoot: root)
    )
    #expect(result.mode == .api)
  }

  @Test func rejectsDuplicateStructuredDataSchemas() {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(throws: BuildError.duplicateStructuredData("Article")) {
      try BuildPipeline.build(
        DuplicateStructuredDataApplication(),
        in: OutputLayout(projectRoot: root)
      )
    }
  }

  @Test func rejectsUnknownRenderedLinksAndAssets() {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(throws: BuildError.unknownPageReference("/missing")) {
      try BuildPipeline.build(BrokenLinkApplication(), in: OutputLayout(projectRoot: root))
    }
    #expect(throws: BuildError.unknownAssetReference("/missing.png")) {
      try BuildPipeline.build(BrokenAssetApplication(), in: OutputLayout(projectRoot: root))
    }
    #expect(throws: BuildError.invalidMetadataURL("/relative")) {
      try BuildPipeline.build(InvalidMetadataApplication(), in: OutputLayout(projectRoot: root))
    }
  }

  @Test func emitsSelectedSyntaxThemeWithoutJavaScript() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let result = try BuildPipeline.build(
      HighlightedApplication(), in: OutputLayout(projectRoot: root))
    let stylesheet = try #require(result.manifest.artifacts.first { $0.mediaType == "text/css" })
    let css = String(
      decoding: try Data(
        contentsOf: root.appendingPathComponent(".robin/build/\(stylesheet.path)")), as: UTF8.self)

    #expect(css.contains("data-robin-highlight-theme=\"xcode-default-dark\""))
    #expect(css.contains("data-robin-highlight=\"keyword\""))
    #expect(!result.manifest.artifacts.contains { $0.mediaType == "text/javascript" })
  }

  @Test func fingerprintsTypedAssetsAndRewritesOnlyReferencedPages() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let asset = try BuildAsset(
      reference: "/images/robin.png",
      path: "images/robin.png",
      bytes: png(width: 1),
      mediaType: "image/png",
      hints: [.preload(as: .image)]
    )
    let small = try BuildAsset(
      reference: "/images/robin-small.png",
      path: "images/robin-small.png",
      bytes: png(width: 320),
      mediaType: "image/png"
    )
    let large = try BuildAsset(
      reference: "/images/robin-large.png",
      path: "images/robin-large.png",
      bytes: png(width: 1280),
      mediaType: "image/png"
    )

    let result = try BuildPipeline.build(
      AssetApplication(),
      configuration: .init(
        assets: [asset, small, large], cdnBaseURL: URL(string: "https://cdn.example.com")!),
      in: OutputLayout(projectRoot: root)
    )

    let image = try #require(result.manifest.artifacts.first { $0.mediaType == "image/png" })
    #expect(image.path.hasPrefix("images/robin-"))
    #expect(image.integrity?.hasPrefix("sha384-") == true)
    #expect(image.imageMetadata?.width == 1)
    #expect(image.imageMetadata?.height == 1)
    #expect(image.imageMetadata?.format == .png)
    let html = try String(
      contentsOf: root.appendingPathComponent(".robin/build/index.html"), encoding: .utf8)
    #expect(html.contains("src=\"https://cdn.example.com/images/robin-"))
    #expect(html.contains("srcset=\"https://cdn.example.com/images/robin-small-"))
    #expect(html.contains("https://cdn.example.com/images/robin-large-"))
    #expect(html.contains("property=\"og:image\" content=\"https://cdn.example.com/images/robin-"))
    #expect(html.contains("property=\"og:image:width\" content=\"1\""))
    #expect(html.contains("property=\"og:image:type\" content=\"image/png\""))
    #expect(html.contains("rel=\"preload\""))
    #expect(html.contains("crossorigin=\"anonymous\""))
    let page = try #require(result.manifest.artifacts.first { $0.path == "index.html" })
    #expect(page.dependencies.contains(image.path))
  }

  @Test func rejectsUntypedScriptsAndSynchronousRemoteAssets() throws {
    #expect(throws: BuildError.unexplainedScript("app.js")) {
      try BuildArtifact(kind: .staticFile, path: "app.js", bytes: [])
    }
    #expect(throws: BuildError.unexplainedScript("blank.js")) {
      try BuildArtifact(
        kind: .staticFile,
        path: "blank.js",
        bytes: [],
        scriptOrigin: .application(exception: "  \n")
      )
    }
    let remote = try RemoteAsset(
      url: URL(string: "https://example.com/logo.svg")!,
      expectedDigest: String(repeating: "0", count: 64),
      reference: "/logo.svg",
      path: "logo.svg",
      mediaType: "image/svg+xml"
    )
    #expect(throws: BuildError.remoteAssetsRequireAsyncBuild) {
      try BuildPipeline.build(
        StaticApplication(),
        configuration: .init(remoteAssets: [remote]),
        in: OutputLayout(projectRoot: temporaryDirectory())
      )
    }
  }

  @Test func emitsDeclarativeSpeculationAndCapabilityScopedNavigation() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let result = try BuildPipeline.build(
      EnhancedApplication(),
      configuration: .init(
        speculationRules: [.init(.prerender, path: "/about", eagerness: .conservative)]),
      in: OutputLayout(projectRoot: root)
    )

    #expect(result.manifest.artifacts.map(\.path).contains("speculation-rules.json"))
    let script = try #require(result.manifest.artifacts.first { $0.path.hasSuffix(".js") })
    #expect(
      script.scriptOrigin
        == .robinDirectCapability(.navigation, selectedBy: "App.clientNavigation"))
    let html = try String(
      contentsOf: root.appendingPathComponent(".robin/build/index.html"), encoding: .utf8)
    #expect(html.contains("<script type=\"speculationrules\">"))
    #expect(html.contains("\"prerender\""))
  }

  @Test func emitsCrossDocumentViewTransitionCSSForSSR() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let executable = try BuildArtifact(kind: .functionBundle, path: "server", bytes: [1])

    let result = try BuildPipeline.build(
      SSRApplication(),
      configuration: .init(runtimeArtifacts: [executable]),
      in: OutputLayout(projectRoot: root)
    )

    #expect(result.mode == .ssr)
    #expect(!result.manifest.artifacts.map(\.path).contains("index.html"))
    let stylesheet = try #require(result.manifest.artifacts.first { $0.mediaType == "text/css" })
    #expect(
      String(
        decoding: try Data(
          contentsOf: root.appendingPathComponent(".robin/build/\(stylesheet.path)")), as: UTF8.self
      ).contains("@view-transition{navigation:auto}"))

    let prerendered = try BuildPipeline.build(
      SSRApplication(),
      configuration: .init(
        runtimeArtifacts: [executable], prerenderedPagePaths: ["/"]),
      in: OutputLayout(projectRoot: root)
    )
    #expect(prerendered.manifest.artifacts.map(\.path).contains("index.html"))
  }

  @Test func appliesProviderLayoutAndEncodesNeutralRoutes() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let executable = try BuildArtifact(kind: .functionBundle, path: "server", bytes: [1])
    let route = try DeploymentRoute(
      pattern: "/api/*", destination: .functionBundle("server"), precedence: 10)

    let result = try BuildPipeline.build(
      APIApplication(),
      configuration: .init(
        runtimeArtifacts: [executable],
        deploymentRoutes: [route],
        routingManifestEncoder: try JSONRoutingManifestEncoder(),
        artifactLayout: .init(
          functionBundles: "functions",
          routeManifests: "config",
          deploymentMetadata: "config"
        )
      ),
      in: OutputLayout(projectRoot: root)
    )

    #expect(result.manifest.artifacts.map(\.path).contains("functions/server"))
    let manifest = try #require(
      result.manifest.artifacts.first { $0.path == "config/routes.json" })
    #expect(manifest.dependencies == ["functions/server"])
    let encodedRoutes = try JSONDecoder().decode(
      [DeploymentRoute].self,
      from: Data(
        contentsOf: root.appendingPathComponent(".robin/build/config/routes.json")))
    #expect(
      encodedRoutes
        == [
          try DeploymentRoute(
            pattern: "/api/*", destination: .functionBundle("functions/server"), precedence: 10)
        ])
    #expect(result.manifest.artifacts.map(\.path).contains("config/deployment.json"))
  }

  @Test func runsChecksumPinnedAssetTransformsAndRecordsTheirIdentity() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let toolURL = root.appendingPathComponent("svg-tool")
    let invocationLog = root.appendingPathComponent("tool-invocations")
    let toolBytes = Array(
      """
      #!/bin/sh
      printf '%s\n' "$*" >> "\(invocationLog.path())"
      case "$1" in
        --skip-system-fonts) input="$3"; output="$4" ;;
        thumbnail) input="$2"; output="$3" ;;
        *) input="$1" ;;
      esac
      case "$2" in
        --output-file=*) output="${2#--output-file=}" ;;
        --bundle) output="${4#--outfile=}" ;;
      esac
      cp "$input" "$output"
      """.utf8)
    try Data(toolBytes).write(to: toolURL)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755], ofItemAtPath: toolURL.path())
    let digest = hexadecimal(SHA256.hash(data: toolBytes))
    let svg = try BuildAsset(
      reference: "/logo.svg",
      path: "logo.svg",
      bytes: Array("<svg></svg>".utf8),
      mediaType: "image/svg+xml",
      transforms: [.optimizeSVG]
    )
    let image = try BuildAsset(
      reference: "/photo.webp",
      path: "photo.webp",
      bytes: webp(width: 320),
      mediaType: "image/webp",
      transforms: [.resizeImage(width: 320, format: .webp)]
    )
    let font = try BuildAsset(
      reference: "/font.woff2",
      path: "font.woff2",
      bytes: [1, 2, 3],
      mediaType: "font/woff2",
      transforms: [.subsetFont(characters: "Robin")],
      hints: [.preload(as: .font)]
    )
    let script = try BuildAsset(
      reference: "/app.ts",
      path: "app.ts",
      bytes: Array("console.log('Robin')".utf8),
      mediaType: "application/typescript",
      transforms: [.bundleScript],
      hints: [.preload(as: .script)],
      scriptOrigin: .application(exception: "Analytics integration")
    )
    let tool = AssetTool(executable: toolURL, expectedDigest: digest)

    let result = try BuildPipeline.build(
      StaticApplication(),
      configuration: .init(
        assets: [svg, image, font, script],
        assetToolchain: .init(image: tool, svg: tool, font: tool, script: tool)
      ),
      in: OutputLayout(projectRoot: root)
    )

    let svgOutput = try #require(
      result.manifest.artifacts.first { $0.mediaType == "image/svg+xml" })
    #expect(svgOutput.transforms == ["svg:optimize@\(digest)"])
    #expect(
      result.manifest.artifacts.first { $0.mediaType == "image/webp" }?.imageMetadata?.width
        == 320)
    #expect(result.manifest.artifacts.contains { $0.mediaType == "font/woff2" })
    let scriptOutput = try #require(
      result.manifest.artifacts.first { $0.mediaType == "text/javascript" })
    #expect(scriptOutput.scriptOrigin == .application(exception: "Analytics integration"))

    _ = try BuildPipeline.build(
      StaticApplication(),
      configuration: .init(
        assets: [svg, image, font, script],
        assetToolchain: .init(image: tool, svg: tool, font: tool, script: tool)
      ),
      in: OutputLayout(projectRoot: root)
    )
    let invocations = try String(contentsOf: invocationLog, encoding: .utf8)
    let invocationCount = invocations.split(separator: "\n").count
    #expect(invocationCount == 4)
    #expect(invocations.contains(" 320 --height=2147483647"))
  }

  @Test func enforcesRemotePinsAndVerifiesCachedBytes() async throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let layout = OutputLayout(projectRoot: root)
    let url = URL(string: "https://example.com/logo.svg")!
    let unpinned = try RemoteAsset(
      url: url,
      reference: "/logo.svg",
      path: "logo.svg",
      mediaType: "image/svg+xml"
    )
    do {
      _ = try await BuildPipeline.build(
        StaticApplication(), configuration: .init(remoteAssets: [unpinned]), in: layout)
      Issue.record("Expected an unpinned production asset to fail")
    } catch {
      #expect(error as? BuildError == .unpinnedRemoteAsset(url.absoluteString))
    }

    let digest = String(repeating: "0", count: 64)
    let cache = layout.path(for: .cache).appendingPathComponent("remote")
    try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
    try Data([1]).write(to: cache.appendingPathComponent(digest))
    let pinned = try RemoteAsset(
      url: url,
      expectedDigest: digest,
      reference: "/logo.svg",
      path: "logo.svg",
      mediaType: "image/svg+xml"
    )
    do {
      _ = try await BuildPipeline.build(
        StaticApplication(), configuration: .init(remoteAssets: [pinned]), in: layout)
      Issue.record("Expected corrupt remote cache bytes to fail")
    } catch {
      #expect(error as? BuildError == .remoteAssetDigestMismatch(url.absoluteString))
    }
  }

  @Test func packagesNativeAndWASIOutputsWithDeterministicRuntimeMetadata() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let library = try BuildArtifact(
      kind: .runtimeLibrary,
      path: "libswiftCore.so",
      bytes: [2]
    )
    let native = try BuildArtifact(
      kind: .functionBundle,
      path: "bootstrap",
      bytes: [1],
      dependencies: ["libswiftCore.so"]
    )
    let wasi = try BuildArtifact(
      kind: .webAssembly,
      path: "application.wasm",
      bytes: [0, 97, 115, 109, 1, 0, 0, 0]
    )
    let adapter = try BuildArtifact(
      kind: .hostAdapter,
      path: "adapter.js",
      bytes: Array("export {}".utf8),
      mediaType: "text/javascript",
      scriptOrigin: .hostAdapter(runtime: "wasi-http", selectedBy: "DeploymentRuntime")
    )
    let route = try DeploymentRoute(
      pattern: "/api/*",
      destination: .webAssembly("application.wasm")
    )
    let configuration = BuildConfiguration(
      runtimeArtifacts: [native, wasi, adapter, library],
      deploymentRoutes: [route],
      routingManifestEncoder: try JSONRoutingManifestEncoder(),
      artifactLayout: .init(
        functionBundles: "functions",
        webAssembly: "components",
        hostAdapters: "adapters",
        runtimeLibraries: "lib",
        deploymentMetadata: "config"
      ),
      runtimes: [
        try DeploymentRuntime(
          .lambda,
          artifact: "bootstrap",
          architecture: .arm64,
          entryPoint: "bootstrap",
          environment: ["DATABASE_URL"],
          toolchain: "Swift 6.3.3 Linux",
          containerImage: "swift:6.3.3-amazonlinux2",
          maximumDurationMilliseconds: 30_000,
          maximumMemoryMebibytes: 512,
          maximumArtifactBytes: 52_428_800
        ),
        try DeploymentRuntime(
          .wasiHTTP,
          artifact: "application.wasm",
          architecture: .wasm32,
          entryPoint: "wasi:http/incoming-handler",
          hostAdapter: "adapter.js"
        ),
      ]
    )

    let first = try BuildPipeline.build(
      APIApplication(), configuration: configuration, in: OutputLayout(projectRoot: root))
    let firstManifest = try first.manifest.encoded()
    let second = try BuildPipeline.build(
      APIApplication(), configuration: configuration, in: OutputLayout(projectRoot: root))

    #expect(try second.manifest.encoded() == firstManifest)
    #expect(first.manifest.artifacts.map(\.path).contains("functions/bootstrap"))
    #expect(first.manifest.artifacts.map(\.path).contains("components/application.wasm"))
    #expect(first.manifest.artifacts.map(\.path).contains("adapters/adapter.js"))
    #expect(first.manifest.artifacts.map(\.path).contains("lib/libswiftCore.so"))
    #expect(
      first.manifest.artifacts.first { $0.path == "functions/bootstrap" }?.dependencies
        == ["lib/libswiftCore.so"])
    #expect(
      first.manifest.artifacts.first { $0.path == "config/deployment.json" }?.dependencies
        == ["adapters/adapter.js", "components/application.wasm", "functions/bootstrap"])
    let routes = try JSONDecoder().decode(
      [DeploymentRoute].self,
      from: Data(contentsOf: root.appendingPathComponent(".robin/build/routes.json"))
    )
    #expect(routes.first?.destination == .webAssembly("components/application.wasm"))
    let deploymentData = try Data(
      contentsOf: root.appendingPathComponent(".robin/build/config/deployment.json"))
    let deployment = try JSONDecoder().decode(TestDeployment.self, from: deploymentData)
    #expect(deployment.runtimes.map(\.interface) == ["lambda", "wasiHTTP"])
    #expect(
      deployment.runtimes.map(\.artifact) == [
        "functions/bootstrap", "components/application.wasm",
      ])
    #expect(!String(decoding: deploymentData, as: UTF8.self).contains("DATABASE_URL="))
  }

  @Test func rejectsMissingAndIncompatibleRuntimeArtifacts() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let native = try BuildArtifact(kind: .functionBundle, path: "bootstrap", bytes: [1, 2])
    let missing = try DeploymentRuntime(
      .lambda, artifact: "missing", architecture: .arm64)
    let incompatible = try DeploymentRuntime(
      .wasiHTTP, artifact: "bootstrap", architecture: .wasm32)

    #expect(throws: BuildError.invalidRuntimeArtifact("missing")) {
      try BuildPipeline.build(
        APIApplication(),
        configuration: .init(runtimeArtifacts: [native], runtimes: [missing]),
        in: OutputLayout(projectRoot: root)
      )
    }
    #expect(throws: BuildError.invalidRuntimeArtifact("bootstrap")) {
      try BuildPipeline.build(
        APIApplication(),
        configuration: .init(runtimeArtifacts: [native], runtimes: [incompatible]),
        in: OutputLayout(projectRoot: root)
      )
    }
    let sizeLimited = try DeploymentRuntime(
      .lambda,
      artifact: "bootstrap",
      architecture: .arm64,
      maximumArtifactBytes: 1
    )
    #expect(
      throws: BuildError.runtimeArtifactTooLarge(
        artifact: "bootstrap", maximumBytes: 1, actualBytes: 2)
    ) {
      try BuildPipeline.build(
        APIApplication(),
        configuration: .init(runtimeArtifacts: [native], runtimes: [sizeLimited]),
        in: OutputLayout(projectRoot: root)
      )
    }
    #expect(throws: BuildError.invalidRuntimeConfiguration("wasiHTTP:arm64")) {
      try DeploymentRuntime(.wasiHTTP, artifact: "app.wasm", architecture: .arm64)
    }
    #expect(throws: BuildError.invalidRuntimeConfiguration("environment")) {
      try DeploymentRuntime(
        .lambda,
        artifact: "bootstrap",
        architecture: .arm64,
        environment: ["DATABASE-URL"]
      )
    }
    #expect(throws: BuildError.invalidRuntimeConfiguration("hostAdapter")) {
      try DeploymentRuntime(
        .webAssembly,
        artifact: "app.wasm",
        architecture: .wasm32
      )
    }
    #expect(throws: BuildError.invalidRuntimeConfiguration("maximumDurationMilliseconds")) {
      try DeploymentRuntime(
        .lambda,
        artifact: "bootstrap",
        architecture: .arm64,
        maximumDurationMilliseconds: 0
      )
    }
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }

  private func hexadecimal<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
    let digits = Array("0123456789abcdef".utf8)
    return String(
      decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 0x0f)]] }, as: UTF8.self)
  }

  private func png(width: Int, height: Int = 1) -> [UInt8] {
    [
      137, 80, 78, 71, 13, 10, 26, 10,
      0, 0, 0, 13, 73, 72, 68, 82,
      UInt8((width >> 24) & 0xff), UInt8((width >> 16) & 0xff),
      UInt8((width >> 8) & 0xff), UInt8(width & 0xff),
      UInt8((height >> 24) & 0xff), UInt8((height >> 16) & 0xff),
      UInt8((height >> 8) & 0xff), UInt8(height & 0xff),
    ]
  }

  private func webp(width: Int, height: Int = 1) -> [UInt8] {
    let encodedWidth = width - 1
    let encodedHeight = height - 1
    return Array("RIFF".utf8) + [0, 0, 0, 0] + Array("WEBPVP8X".utf8)
      + [
        10, 0, 0, 0, 0, 0, 0, 0,
        UInt8(encodedWidth & 0xff), UInt8((encodedWidth >> 8) & 0xff),
        UInt8((encodedWidth >> 16) & 0xff), UInt8(encodedHeight & 0xff),
        UInt8((encodedHeight >> 8) & 0xff), UInt8((encodedHeight >> 16) & 0xff),
      ]
  }
}

private struct StaticApplication: App {
  var metadata: Metadata {
    Metadata(
      title: "Default",
      site: "Robin",
      description: "Swift-native web apps.",
      canonicalURL: "https://example.com",
      language: "en-GB",
      author: .init("Robin Author", url: "https://example.com/author"),
      openGraph: .init(title: "Robin on Open Graph"),
      xCard: .init(description: "Robin on X"),
      robots: .init(follow: false),
      alternateLanguages: [.init("fr", url: "https://example.com/fr")],
      icons: [
        .init(url: "https://example.com/icon.svg", sizes: "any", mediaType: "image/svg+xml")
      ],
      manifestURL: "https://example.com/site.webmanifest",
      structuredData: [
        .softwareApplication(
          .init(operatingSystem: "Linux and macOS", category: "DeveloperApplication"))
      ]
    )
  }
  var theme: any ApplicationTheme { Theme.default }

  @PagesBuilder var pages: PageList {
    HomePage()
    AboutPage()
  }
}

private struct BrokenLinkApplication: App {
  @PagesBuilder var pages: PageList { BrokenLinkPage() }
}

private struct BrokenLinkPage: Page {
  let path = "/"
  var body: ComponentContent { Link("/missing") { "Missing" }.body }
}

private struct BrokenAssetApplication: App {
  @PagesBuilder var pages: PageList { BrokenAssetPage() }
}

private struct BrokenAssetPage: Page {
  let path = "/"
  var body: ComponentContent { Image(source: "/missing.png", alternateText: "Missing").body }
}

private struct HighlightedApplication: App {
  @PagesBuilder var pages: PageList { HighlightedPage() }
}

private struct HighlightedPage: Page {
  let path = "/"
  var body: ComponentContent {
    CodeBlock("let answer = 42", language: "swift", theme: .xcodeDefaultDark).body
  }
}

private struct APIApplication: App {
  var metadata: Metadata { Metadata(title: "API") }

  @RoutesBuilder var routes: RouteList {
    TestRoute()
  }
}

private struct AssetApplication: App {
  var metadata: Metadata {
    Metadata(
      title: "Assets",
      image: .init(url: "/images/robin.png", alternativeText: "Robin"))
  }

  @PagesBuilder var pages: PageList {
    AssetPage()
  }
}

private struct InvalidMetadataApplication: App {
  var metadata: Metadata { Metadata(canonicalURL: "/relative") }
  @PagesBuilder var pages: PageList { HomePage() }
}

private struct EnhancedApplication: App {
  var metadata: Metadata { Metadata(title: "Enhanced") }
  var clientNavigation: ClientNavigation { .enabled }

  @PagesBuilder var pages: PageList {
    HomePage()
    AboutPage()
  }
}

private struct SSRApplication: App {
  var metadata: Metadata { Metadata(title: "SSR") }

  @PagesBuilder var pages: PageList {
    HomePage()
  }

  @RoutesBuilder var routes: RouteList {
    TestRoute()
  }
}

private struct DuplicateStructuredDataApplication: App {
  var metadata: Metadata {
    let article = StructuredData.Article()
    return Metadata(structuredData: [.article(article), .article(article)])
  }

  @PagesBuilder var pages: PageList { HomePage() }
}

private struct TestRoute: ApplicationRoute {
  let applicationRouteIdentifier = "test"
}

private struct TestDeployment: Decodable {
  struct Runtime: Decodable {
    let interface: String
    let artifact: String
  }

  let runtimes: [Runtime]
}

private struct HomePage: Page {
  let path = "/"
  var metadata: Metadata { Metadata(title: "Home") }
  @ViewBuilder var body: ComponentContent {
    Text { "Hello" }.font(.body)
    Text { "Only home" }.padding(.sm)
  }
}

private struct AboutPage: Page {
  let path = "/about"
  @ViewBuilder var body: ComponentContent { Text { "About" }.font(.body) }
}

private struct AssetPage: Page {
  let path = "/"
  @ViewBuilder var body: ComponentContent {
    Image(
      source: "/images/robin.png",
      alternateText: "Robin",
      variants: [
        .init("/images/robin-small.png", width: 320),
        .init("/images/robin-large.png", width: 1280),
      ],
      sizes: "100vw"
    )
  }
}
