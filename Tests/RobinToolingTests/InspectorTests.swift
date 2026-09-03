import Foundation
import Testing

@testable import RobinBuild
@testable import RobinTooling

@Suite("Local development inspector")
struct InspectorTests {
  @Test func sourceOpeningRequiresLoopbackAndContainedExistingPaths() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let source = root.appendingPathComponent("Sources/App.swift")
    try FileManager.default.createDirectory(
      at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data().write(to: source)

    #expect(
      try SourceInspector.resolve("Sources/App.swift", from: root, requestedHost: "localhost")
        == source)
    #expect(throws: SourceInspectorError.self) {
      try SourceInspector.resolve("Sources/App.swift", from: root, requestedHost: "example.com")
    }
    #expect(throws: SourceInspectorError.self) {
      try SourceInspector.resolve("../secret", from: root, requestedHost: "127.0.0.1")
    }
  }

  @Test func buildInspectorExplainsTypedInteractionLowering() {
    let entry = BuildManifest.Entry(
      kind: .staticFile,
      path: "assets/navigation.js",
      digest: "digest",
      byteCount: 1,
      dependencies: [],
      mediaType: "text/javascript",
      integrity: nil,
      transforms: [],
      scriptOrigin: .robinDirectCapability(.navigation, selectedBy: "App.clientNavigation"),
      imageMetadata: nil
    )
    #expect(
      BuildInspector.interactions(in: BuildManifest(artifacts: [entry])) == [
        .init(
          path: "assets/navigation.js",
          lowering: "direct capability: navigation",
          selectedBy: "App.clientNavigation"
        )
      ])
  }
}
