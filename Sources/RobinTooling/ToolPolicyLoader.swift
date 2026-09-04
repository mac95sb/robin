import Foundation

package enum ToolPolicyLoaderError: Error, Equatable, CustomStringConvertible, Sendable {
  case evaluationFailed(Int32, String)

  package var description: String {
    switch self {
    case .evaluationFailed(let status, let diagnostic):
      diagnostic.isEmpty
        ? "pkl could not evaluate robin.pkl (status \(status))."
        : "pkl could not evaluate robin.pkl: \(diagnostic)"
    }
  }
}

package struct ToolPolicyLoader {
  package static func load(at projectRoot: URL) throws -> ToolPolicy? {
    let source = projectRoot.appendingPathComponent("robin.pkl")
    guard FileManager.default.fileExists(atPath: source.path) else { return nil }

    let process = Process()
    let output = Pipe()
    let errors = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["pkl", "eval", "-f", "json", source.path]
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      let diagnostic = String(
        decoding: errors.fileHandleForReading.readDataToEndOfFile(),
        as: UTF8.self
      ).trimmingCharacters(in: .whitespacesAndNewlines)
      throw ToolPolicyLoaderError.evaluationFailed(process.terminationStatus, diagnostic)
    }
    let policy = try JSONDecoder().decode(
      ToolPolicy.self,
      from: output.fileHandleForReading.readDataToEndOfFile()
    )
    try policy.validate()
    return policy
  }
}
