import Foundation
import RobinCore

package struct ProjectDoctor {
  package static func diagnose(
    at projectRoot: URL,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> [ToolDiagnostic] {
    var diagnostics = ["swift", "mise", "pkl", "hk"].compactMap { executable in
      isAvailable(executable) ? nil : missingExecutable(executable)
    }
    if isAvailable("swift") {
      diagnostics += swiftVersionDiagnostics(environment: environment)
    }
    let layout = OutputLayout(projectRoot: projectRoot)
    if RobinArtifact.allCases.contains(where: { !layout.contains(layout.path(for: $0)) }) {
      diagnostics.append(
        .init(
          code: "unsafe-output-layout",
          severity: .error,
          message: "A generated-output category escapes the project's .robin directory.",
          remediation: "Resolve project-root symlinks and remove any .robin symlink."
        ))
    }
    if !FileManager.default.fileExists(
      atPath: projectRoot.appendingPathComponent("Package.resolved").path)
    {
      diagnostics.append(
        .init(
          code: "unresolved-dependencies",
          severity: .warning,
          message: "Package.resolved is missing.",
          remediation: "Run `swift package resolve` before deployment."
        ))
    }
    diagnostics += ProjectLinter.featureFlagDiagnostics(at: projectRoot)
    return diagnostics
  }

  private static func swiftVersionDiagnostics(environment: [String: String]) -> [ToolDiagnostic] {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["swift", "--version"]
    process.standardOutput = output
    process.standardError = output
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return [missingExecutable("swift")]
    }
    let text = String(
      decoding: output.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )
    guard let version = swiftVersion(in: text) else {
      return [
        .init(
          code: "swift-version",
          severity: .error,
          message: "The Swift compiler version could not be determined.",
          remediation: "Install stable Swift 6.3.3 through `mise install`."
        )
      ]
    }
    if version.isPrerelease, environment["ROBIN_ALLOW_PRERELEASE_SWIFT"] != "1" {
      return [
        .init(
          code: "swift-prerelease",
          severity: .error,
          message: "Detected pre-release Swift \(version.text).",
          remediation: "Install stable Swift 6.3.3 or set the explicit development override."
        )
      ]
    }
    guard version.components.lexicographicallyPrecedes([6, 3, 3]) == false else {
      return [
        .init(
          code: "swift-version",
          severity: .error,
          message: "Detected Swift \(version.text), older than the 6.3.3 minimum.",
          remediation: "Run `mise install swift@6.3.3`."
        )
      ]
    }
    return [
      .init(
        code: "swift-version",
        severity: .note,
        message: "Detected stable Swift \(version.text); CI baseline is 6.3.3."
      )
    ]
  }

  private static func swiftVersion(in output: String) -> (
    text: String, components: [Int], isPrerelease: Bool
  )? {
    guard let marker = output.range(of: "Swift version ") else { return nil }
    let text = output[marker.upperBound...].split(whereSeparator: \.isWhitespace).first.map(
      String.init)
    guard let text else { return nil }
    let stable = text.split(separator: "-", maxSplits: 1).first.map(String.init) ?? text
    let components = stable.split(separator: ".").compactMap { Int($0) }
    guard components.count >= 3 else { return nil }
    return (text, Array(components.prefix(3)), text.contains("-"))
  }

  private static func isAvailable(_ executable: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["which", executable]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }

  private static func missingExecutable(_ executable: String) -> ToolDiagnostic {
    .init(
      code: "missing-tool",
      severity: .error,
      message: "Required executable `\(executable)` is unavailable.",
      remediation: "Run `mise install` from the project root."
    )
  }
}
