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
    #expect(html.contains("<!doctype html><html lang=\"en-GB\">"))
    #expect(html.contains("<title>Home | Robin</title>"))
    #expect(html.contains("property=\"og:title\" content=\"Home | Robin\""))
    #expect(html.contains("name=\"twitter:description\" content=\"Swift-native web apps.\""))
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

  @Test func validatesModeSpecificExecutableArtifacts() throws {
    let executable = try BuildArtifact(kind: .functionBundle, path: "server", bytes: [1])
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(throws: BuildError.staticApplicationHasExecutableArtifacts) {
      try BuildPipeline.build(
        StaticApplication(),
        configuration: .init(executableArtifacts: [executable]),
        in: OutputLayout(projectRoot: root)
      )
    }
    #expect(throws: BuildError.missingExecutableArtifact(.api)) {
      try BuildPipeline.build(APIApplication(), in: OutputLayout(projectRoot: root))
    }
    #expect(throws: BuildError.duplicateArtifactPath("server")) {
      try BuildPipeline.build(
        APIApplication(),
        configuration: .init(executableArtifacts: [executable, executable]),
        in: OutputLayout(projectRoot: root)
      )
    }
    let result = try BuildPipeline.build(
      APIApplication(),
      configuration: .init(executableArtifacts: [executable]),
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
      configuration: .init(executableArtifacts: [executable]),
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
        executableArtifacts: [executable], prerenderedPagePaths: ["/"]),
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
        executableArtifacts: [executable],
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

private struct APIApplication: App {
  var metadata: Metadata { Metadata(title: "API") }

  @RoutesBuilder var routes: RouteList {
    TestRoute()
  }
}

private struct AssetApplication: App {
  var metadata: Metadata { Metadata(title: "Assets") }

  @PagesBuilder var pages: PageList {
    AssetPage()
  }
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
    let article = StructuredData.Article(
      author: .init("Robin"),
      datePublished: Date(timeIntervalSince1970: 0)
    )
    return Metadata(structuredData: [.article(article), .article(article)])
  }

  @PagesBuilder var pages: PageList { HomePage() }
}

private struct TestRoute: ApplicationRoute {
  let applicationRouteIdentifier = "test"
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
