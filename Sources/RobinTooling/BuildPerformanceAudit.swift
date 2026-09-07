import Foundation
import RobinBuild

/// Reports uncompressed artifact sizes, not browser timing or network transfer estimates.
package enum BuildPerformanceAudit {
  package static func audit(at projectRoot: URL) -> [ToolDiagnostic] {
    let root = projectRoot.appendingPathComponent(".robin/build").resolvingSymlinksInPath()
    let manifestURL = root.appendingPathComponent("manifest.json")
    guard FileManager.default.fileExists(atPath: manifestURL.path) else {
      return [
        .init(
          code: "performance-skipped", severity: .note,
          message: "Offline performance checks skipped: no build manifest.",
          remediation: "Run `robin build`, then `robin lint` to inspect artifact sizes.")
      ]
    }
    do {
      let manifest = try JSONDecoder().decode(
        BuildManifest.self, from: Data(contentsOf: manifestURL))
      var totals: [String: Int] = [:]
      var seen = Set<String>()
      for artifact in manifest.artifacts where artifact.kind == .staticFile {
        guard seen.insert(artifact.path).inserted else {
          throw CocoaError(.fileReadCorruptFile)
        }
        let file = root.appendingPathComponent(artifact.path).resolvingSymlinksInPath()
        guard file.path.hasPrefix(root.path + "/") else {
          throw CocoaError(.fileReadNoPermission)
        }
        let values = try file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true, let size = values.fileSize else {
          throw CocoaError(.fileReadCorruptFile)
        }
        let inferredType: String
        switch file.pathExtension.lowercased() {
        case "html", "htm": inferredType = "text/html"
        case "css": inferredType = "text/css"
        case "js", "mjs": inferredType = "text/javascript"
        default: inferredType = "Other"
        }
        totals[artifact.mediaType ?? inferredType, default: 0] += size
      }
      var diagnostics = totals.sorted { $0.key < $1.key }.map { type, bytes in
        ToolDiagnostic(
          code: "artifact-size", severity: .note, message: type,
          measurement: .init(value: Double(bytes), unit: "bytes"))
      }
      diagnostics.append(
        .init(
          code: "performance-scope", severity: .note,
          message:
            "Sizes cover unique static artifacts in the last build, before compression. They are not page-load timings.",
          remediation:
            "Rebuild after source changes. Use `robin lint --url https://your-site.example` for a browser audit."
        ))
      return diagnostics
    } catch {
      return [
        .init(
          code: "performance-build-invalid", severity: .error,
          message:
            "Could not measure the build: its manifest or artifact files are invalid or missing.",
          remediation: "Run `robin build` to regenerate the output, then retry.")
      ]
    }
  }
}
