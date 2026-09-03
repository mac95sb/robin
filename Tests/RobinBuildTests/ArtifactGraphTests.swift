import Foundation
import RobinBuild
import RobinCore
import Testing

@Suite("Deterministic build artifact graph")
struct ArtifactGraphTests {
  @Test func materializesContentAddressedArtifactsInDependencyOrder() throws {
    let projectRoot = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: projectRoot) }
    let layout = OutputLayout(projectRoot: projectRoot)
    let persistentData = projectRoot.appendingPathComponent("application.sqlite")
    try FileManager.default.createDirectory(at: projectRoot, withIntermediateDirectories: true)
    try Data("persistent".utf8).write(to: persistentData)
    let stylesheet = try BuildArtifact(
      kind: .staticFile,
      path: "assets/site.css",
      bytes: Array("body{}".utf8)
    )
    let page = try BuildArtifact(
      kind: .staticFile,
      path: "index.html",
      bytes: Array("<h1>Robin</h1>".utf8),
      dependencies: [stylesheet.path]
    )

    let output = layout.path(for: .build).appendingPathComponent("index.html")
    let first = try ArtifactGraph([page, stylesheet]).materialize(in: layout)
    let unchangedDate = Date(timeIntervalSince1970: 1)
    try FileManager.default.setAttributes(
      [.modificationDate: unchangedDate], ofItemAtPath: output.path())
    let second = try ArtifactGraph([stylesheet, page]).materialize(in: layout)

    #expect(first == second)
    #expect(first.artifacts.map(\.path) == ["assets/site.css", "index.html"])
    #expect(first.artifacts[0].digest.count == 64)
    #expect(
      try String(
        contentsOf: output,
        encoding: .utf8
      ) == "<h1>Robin</h1>"
    )
    #expect(
      try #require(
        FileManager.default.attributesOfItem(atPath: output.path())[.modificationDate] as? Date
      ) == unchangedDate
    )
    #expect(
      FileManager.default.fileExists(
        atPath: layout.path(for: .build).appendingPathComponent("manifest.json").path())
    )
    #expect(
      FileManager.default.fileExists(
        atPath: layout.path(for: .cache).appendingPathComponent("build").appendingPathComponent(
          first.artifacts[0].digest
        ).path()
      ))

    try ArtifactGraph([]).materialize(in: layout)
    #expect(!FileManager.default.fileExists(atPath: output.path()))
    #expect(FileManager.default.fileExists(atPath: persistentData.path()))
    #expect(
      FileManager.default.fileExists(
        atPath: layout.path(for: .cache).appendingPathComponent("build").appendingPathComponent(
          first.artifacts[0].digest
        ).path()
      ))

    let cached = layout.path(for: .cache).appendingPathComponent("build").appendingPathComponent(
      first.artifacts[0].digest)
    try Data([0]).write(to: cached)
    #expect(throws: BuildError.corruptedCacheEntry(first.artifacts[0].digest)) {
      try ArtifactGraph([stylesheet, page]).materialize(in: layout)
    }
  }

  @Test func rejectsUnsafeAndInvalidGraphs() throws {
    #expect(throws: BuildError.invalidArtifactPath("../outside")) {
      try BuildArtifact(kind: .staticFile, path: "../outside", bytes: [])
    }
    let duplicate = try BuildArtifact(kind: .staticFile, path: "index.html", bytes: [])
    #expect(throws: BuildError.duplicateArtifactPath("index.html")) {
      try ArtifactGraph([duplicate, duplicate])
    }
    let missing = try BuildArtifact(
      kind: .routeManifest,
      path: "routes.json",
      bytes: [],
      dependencies: ["function"]
    )
    #expect(
      throws: BuildError.missingDependency(artifact: "routes.json", dependency: "function")
    ) {
      try ArtifactGraph([missing])
    }
    let first = try BuildArtifact(
      kind: .staticFile, path: "a", bytes: [], dependencies: ["b"])
    let second = try BuildArtifact(
      kind: .staticFile, path: "b", bytes: [], dependencies: ["a"])
    #expect(throws: BuildError.dependencyCycle(["a", "b", "a"])) {
      try ArtifactGraph([second, first])
    }
  }
}
