import Foundation

package struct ProjectLinter {
  package static func lint(at projectRoot: URL) -> [ToolDiagnostic] {
    var diagnostics: [ToolDiagnostic] = []
    let requiredFiles = ["Package.swift", "mise.toml", "hk.pkl", "AGENTS.md"]
    for path in requiredFiles where !exists(path, at: projectRoot) {
      diagnostics.append(
        .init(
          code: "missing-file",
          severity: .error,
          message: "Required project file is missing.",
          location: .init(path: path),
          remediation: "Restore \(path) from the matching Robin template."
        ))
    }

    let gitignore = text(".gitignore", at: projectRoot) ?? ""
    if !gitignore.split(whereSeparator: \.isNewline).contains(".robin/") {
      diagnostics.append(
        .init(
          code: "generated-output-not-ignored",
          severity: .error,
          message: "Robin-generated output is not ignored.",
          location: .init(path: ".gitignore"),
          remediation: "Add `.robin/` to .gitignore."
        ))
    }

    let package = text("Package.swift", at: projectRoot) ?? ""
    let packageRequirements: [(String, String, String)] = [
      (
        "swift-tools-version", "// swift-tools-version: 6.3",
        "Set the Package.swift tools version to 6.3."
      ),
      (
        "swift-language-mode", "swiftLanguageModes: [.v6]",
        "Set `swiftLanguageModes: [.v6]` on the package."
      ),
      (
        "strict-memory-safety", ".strictMemorySafety()",
        "Enable `.strictMemorySafety()` in the application's Swift settings."
      ),
      (
        "warnings-as-errors", "-warnings-as-errors",
        "Add `-warnings-as-errors` to the application's Swift settings."
      ),
      (
        "nonisolated-nonsending", "NonisolatedNonsendingByDefault",
        "Enable the NonisolatedNonsendingByDefault upcoming feature."
      ),
      (
        "immutable-weak-captures", "ImmutableWeakCaptures",
        "Enable the ImmutableWeakCaptures upcoming feature."
      ),
    ]
    for (code, token, remediation) in packageRequirements where !package.contains(token) {
      diagnostics.append(
        .init(
          code: code,
          severity: .error,
          message: "Package.swift is missing required Swift 6 configuration.",
          location: .init(path: "Package.swift"),
          remediation: remediation
        ))
    }

    if exists("Sources/ViewModels", at: projectRoot) {
      diagnostics.append(
        .init(
          code: "unsupported-view-model-layer",
          severity: .warning,
          message: "Robin templates use Controller → Service → Model → View, not MVVM.",
          location: .init(path: "Sources/ViewModels"),
          remediation: "Move request handling to Controllers and reusable work to Services."
        ))
    }

    // ponytail: a token scan is enough until real projects demonstrate SwiftSyntax-level noise.
    for source in swiftSources(at: projectRoot) {
      guard let contents = try? String(contentsOf: source, encoding: .utf8) else { continue }
      let rawTokens = ["Raw" + "HTML", "Raw" + "CSS", "Raw" + "JavaScript"]
      for token in rawTokens where contents.contains(token) {
        diagnostics.append(
          .init(
            code: "raw-web-escape-hatch",
            severity: .error,
            message: "\(token) bypasses Robin's typed rendering model.",
            location: .init(path: relativePath(of: source, from: projectRoot)),
            remediation: "Use a semantic component, grouped style modifier, or typed capability."
          ))
      }
      let manualModeTokens = [
        "application" + "Mode", "mode: ." + "static", "mode: ." + "api", "mode: ." + "ssr",
      ]
      if manualModeTokens.contains(where: contents.contains) {
        diagnostics.append(
          .init(
            code: "manual-application-mode",
            severity: .error,
            message: "Application mode must be inferred from registered pages and controllers.",
            location: .init(path: relativePath(of: source, from: projectRoot)),
            remediation: "Remove the mode setting and register only the required surfaces."
          ))
      }
      diagnostics += staleFeatureFlagDiagnostics(
        in: contents, path: relativePath(of: source, from: projectRoot))
    }
    return diagnostics
  }

  package static func featureFlagDiagnostics(at projectRoot: URL) -> [ToolDiagnostic] {
    swiftSources(at: projectRoot).flatMap { source -> [ToolDiagnostic] in
      guard let contents = try? String(contentsOf: source, encoding: .utf8) else { return [] }
      return staleFeatureFlagDiagnostics(
        in: contents, path: relativePath(of: source, from: projectRoot))
    }
  }

  private static func staleFeatureFlagDiagnostics(in contents: String, path: String)
    -> [ToolDiagnostic]
  {
    contents.split(separator: "\n", omittingEmptySubsequences: false).enumerated().compactMap {
      index, line in
      let line = String(line)
      guard line.contains("FeatureFlag("),
        dateIsPast("removalDate:", in: line) || dateIsPast("fixedValueSince:", in: line)
      else { return nil }
      return ToolDiagnostic(
        code: "stale-feature-flag",
        severity: .warning,
        message: "A feature flag is past its declared removal date.",
        location: .init(path: path, line: index + 1),
        remediation: "Remove the flag and its fixed code path."
      )
    }
  }

  private static func dateIsPast(_ label: String, in line: String) -> Bool {
    guard let labelRange = line.range(of: label) else { return false }
    let value = line[labelRange.upperBound...]
    if value.trimmingCharacters(in: .whitespaces).hasPrefix(".distantPast") { return true }
    guard let marker = value.range(of: "timeIntervalSince1970:"),
      let closing = value[marker.upperBound...].firstIndex(of: ")"),
      let timestamp = Double(
        value[marker.upperBound..<closing].trimmingCharacters(in: .whitespaces))
    else { return false }
    return timestamp <= Date().timeIntervalSince1970
  }

  private static func exists(_ path: String, at root: URL) -> Bool {
    FileManager.default.fileExists(atPath: root.appendingPathComponent(path).path)
  }

  private static func text(_ path: String, at root: URL) -> String? {
    try? String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
  }

  private static func swiftSources(at root: URL) -> [URL] {
    let sources = root.appendingPathComponent("Sources", isDirectory: true)
    guard
      let enumerator = FileManager.default.enumerator(
        at: sources,
        includingPropertiesForKeys: [.isRegularFileKey]
      )
    else { return [] }
    return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
  }

  private static func relativePath(of file: URL, from root: URL) -> String {
    file.path.replacingOccurrences(of: root.path + "/", with: "")
  }
}
