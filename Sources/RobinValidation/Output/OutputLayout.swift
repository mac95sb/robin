import Foundation

/// Resolves and validates paths within a project's `.robin` output directory.
public struct OutputLayout: Sendable {
  public let projectRoot: URL

  public init(projectRoot: URL) {
    self.projectRoot = projectRoot.standardizedFileURL
  }

  /// The root directory for all Robin-generated output.
  public var robinRoot: URL { projectRoot.appendingPathComponent(".robin", isDirectory: true) }

  /// Returns the directory assigned to an artifact category.
  public func path(for artifact: RobinArtifact) -> URL {
    robinRoot.appendingPathComponent(artifact.rawValue, isDirectory: true)
  }

  /// Returns whether a file URL resolves to the `.robin` root or one of its descendants.
  public func contains(_ candidate: URL) -> Bool {
    let root = normalizedPath(robinRoot)
    let path = normalizedPath(candidate)
    return path == root || path.hasPrefix(root + "/")
  }

  private func normalizedPath(_ url: URL) -> String {
    var path = url.standardizedFileURL.path(percentEncoded: false)
    while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
    return path
  }
}
