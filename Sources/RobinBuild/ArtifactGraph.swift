import Foundation
import RobinCore

/// Validates and materializes a deterministic build artifact graph.
public struct ArtifactGraph: Sendable {
  private let artifactsByPath: [String: BuildArtifact]
  private let orderedPaths: [String]

  /// Creates a graph and validates every dependency.
  ///
  /// - Parameter artifacts: Final artifacts to include in the graph.
  /// - Throws: ``BuildError`` for duplicate paths, missing dependencies, or cycles.
  public init(_ artifacts: [BuildArtifact]) throws {
    var artifactsByPath: [String: BuildArtifact] = [:]
    for artifact in artifacts {
      guard artifactsByPath.updateValue(artifact, forKey: artifact.path) == nil else {
        throw BuildError.duplicateArtifactPath(artifact.path)
      }
    }
    for artifact in artifacts {
      for dependency in artifact.dependencies where artifactsByPath[dependency] == nil {
        throw BuildError.missingDependency(artifact: artifact.path, dependency: dependency)
      }
    }
    self.artifactsByPath = artifactsByPath
    self.orderedPaths = try Self.order(artifactsByPath)
  }

  /// Writes the graph beneath a project's `.robin` directory.
  ///
  /// Final files are written to `.robin/build`; content-addressed copies are retained under
  /// `.robin/cache/build`. Existing identical files are reused.
  ///
  /// - Parameter layout: The project's validated output layout.
  /// - Returns: The deterministic manifest written alongside the artifacts.
  /// - Throws: ``BuildError/outputEscapesRobinRoot(_:)`` or a filesystem error.
  @discardableResult
  public func materialize(in layout: OutputLayout) throws -> BuildManifest {
    let fileManager = FileManager.default
    let buildRoot = layout.path(for: .build)
    let cacheRoot = layout.path(for: .cache).appendingPathComponent("build", isDirectory: true)
    let manifestURL = buildRoot.appendingPathComponent("manifest.json")
    try fileManager.createDirectory(at: buildRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: cacheRoot, withIntermediateDirectories: true)

    if fileManager.fileExists(atPath: manifestURL.path(percentEncoded: false)) {
      let previous = try JSONDecoder().decode(
        BuildManifest.self, from: Data(contentsOf: manifestURL))
      let currentPaths = Set(orderedPaths)
      for entry in previous.artifacts where !currentPaths.contains(entry.path) {
        guard BuildArtifact.isValid(entry.path) else {
          throw BuildError.invalidArtifactPath(entry.path)
        }
        let stale = try outputURL(for: entry.path, under: buildRoot, layout: layout)
        if fileManager.fileExists(atPath: stale.path(percentEncoded: false)) {
          try fileManager.removeItem(at: stale)
        }
      }
    }

    var entries: [BuildManifest.Entry] = []
    for path in orderedPaths {
      let artifact = artifactsByPath[path]!
      let data = Data(artifact.bytes)
      let digest = ContentDigest.sha256(artifact.bytes)
      let cached = cacheRoot.appendingPathComponent(digest)
      guard layout.contains(cached) else {
        throw BuildError.outputEscapesRobinRoot(cached.path(percentEncoded: false))
      }
      if fileManager.fileExists(atPath: cached.path(percentEncoded: false)) {
        guard try Data(contentsOf: cached) == data else {
          throw BuildError.corruptedCacheEntry(digest)
        }
      } else {
        try data.write(to: cached, options: .atomic)
      }

      let output = try outputURL(for: path, under: buildRoot, layout: layout)
      try fileManager.createDirectory(
        at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
      if (try? Data(contentsOf: output)) != data {
        try data.write(to: output, options: .atomic)
      }
      entries.append(
        .init(
          kind: artifact.kind,
          path: artifact.path,
          digest: digest,
          byteCount: artifact.bytes.count,
          dependencies: artifact.dependencies,
          mediaType: artifact.mediaType,
          integrity: artifact.integrity,
          transforms: artifact.transforms,
          scriptOrigin: artifact.scriptOrigin,
          imageMetadata: artifact.imageMetadata
        ))
    }

    let manifest = BuildManifest(artifacts: entries)
    try manifest.encoded().write(to: manifestURL, options: .atomic)
    return manifest
  }

  private func outputURL(for path: String, under root: URL, layout: OutputLayout) throws -> URL {
    let output = path.split(separator: "/").reduce(root) {
      $0.appendingPathComponent(String($1))
    }
    guard layout.contains(output) else { throw BuildError.outputEscapesRobinRoot(path) }
    return output
  }

  private static func order(_ artifacts: [String: BuildArtifact]) throws -> [String] {
    enum Visit { case visiting, visited }
    var visits: [String: Visit] = [:]
    var stack: [String] = []
    var ordered: [String] = []

    func visit(_ path: String) throws {
      if visits[path] == .visited { return }
      if visits[path] == .visiting {
        let start = stack.firstIndex(of: path) ?? stack.startIndex
        throw BuildError.dependencyCycle(Array(stack[start...]) + [path])
      }
      visits[path] = .visiting
      stack.append(path)
      for dependency in artifacts[path]!.dependencies { try visit(dependency) }
      stack.removeLast()
      visits[path] = .visited
      ordered.append(path)
    }

    for path in artifacts.keys.sorted() { try visit(path) }
    return ordered
  }

}
