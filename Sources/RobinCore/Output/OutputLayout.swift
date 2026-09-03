import Foundation
import SystemPackage

/// Resolves and validates paths within a project's `.robin` output directory.
///
/// All Robin-generated files live under a `.robin` directory at the project
/// root, separated by ``RobinArtifact`` category. ``contains(_:)`` guards
/// against path traversal so tooling never writes outside that root.
public struct OutputLayout: Sendable {
  /// The project's root directory, standardized at initialization.
  public let projectRoot: URL

  /// Creates a layout rooted at a project directory.
  ///
  /// - Parameter projectRoot: The project's root directory.
  public init(projectRoot: URL) {
    self.projectRoot = projectRoot.standardizedFileURL
  }

  /// The root directory for all Robin-generated output.
  public var robinRoot: URL { projectRoot.appendingPathComponent(".robin", isDirectory: true) }

  /// Returns the directory assigned to an artifact category.
  ///
  /// The directory is not created; callers decide when to materialize it.
  ///
  /// - Parameter artifact: The artifact category to resolve.
  /// - Returns: `robinRoot` appended with the category's directory name.
  public func path(for artifact: RobinArtifact) -> URL {
    robinRoot.appendingPathComponent(artifact.rawValue, isDirectory: true)
  }

  /// Returns whether a file URL resolves to the `.robin` root or one of its descendants.
  ///
  /// Use this to reject paths that escape the output directory through `..`
  /// segments or symlinks before writing generated files.
  ///
  /// - Parameter candidate: The file URL to test.
  /// - Returns: `true` when `candidate` is the `.robin` root or lies inside it.
  public func contains(_ candidate: URL) -> Bool {
    let expectedRoot = FilePath(
      projectRoot.resolvingSymlinksInPath()
        .appendingPathComponent(".robin", isDirectory: true).path(percentEncoded: false)
    ).lexicallyNormalized()
    let root = normalizedPath(robinRoot)
    guard root == expectedRoot else { return false }
    var path = normalizedPath(candidate)
    return path == root || path.removePrefix(root)
  }

  private func normalizedPath(_ url: URL) -> FilePath {
    var existing = url.standardizedFileURL
    var missingComponents: [String] = []
    while !FileManager.default.fileExists(atPath: existing.path(percentEncoded: false)) {
      let parent = existing.deletingLastPathComponent()
      guard parent != existing else { break }
      missingComponents.append(existing.lastPathComponent)
      existing = parent
    }
    var resolved = existing.resolvingSymlinksInPath()
    for component in missingComponents.reversed() {
      resolved.appendPathComponent(component)
    }
    return FilePath(resolved.path(percentEncoded: false))
      .lexicallyNormalized()
  }
}
