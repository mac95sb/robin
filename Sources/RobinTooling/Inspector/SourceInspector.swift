import Foundation

package enum SourceInspectorError: Error, Equatable, Sendable {
  case nonLoopbackHost(String)
  case invalidPath(String)
}

package struct SourceInspector {
  package static func resolve(
    _ relativePath: String,
    from projectRoot: URL,
    requestedHost: String
  ) throws -> URL {
    guard ["127.0.0.1", "::1", "localhost"].contains(requestedHost.lowercased()) else {
      throw SourceInspectorError.nonLoopbackHost(requestedHost)
    }
    guard !relativePath.isEmpty, !relativePath.hasPrefix("/"), !relativePath.contains("\\") else {
      throw SourceInspectorError.invalidPath(relativePath)
    }
    let root = projectRoot.resolvingSymlinksInPath()
    let candidate = root.appendingPathComponent(relativePath).resolvingSymlinksInPath()
    guard candidate.path.hasPrefix(root.path + "/"),
      FileManager.default.fileExists(atPath: candidate.path)
    else { throw SourceInspectorError.invalidPath(relativePath) }
    return candidate
  }
}
