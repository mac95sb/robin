import Foundation
import RobinCore

package enum RobinCommandRunnerError: Error, Equatable, CustomStringConvertible, Sendable {
  case commandFailed(String, Int32)
  case buildBudgetExceeded(actualMilliseconds: Int, budgetMilliseconds: Int)
  case missingBuildOutput
  case outputEscapesRobinRoot

  package var description: String {
    switch self {
    case .commandFailed(let command, let status):
      "`\(command)` failed with status \(status)."
    case .buildBudgetExceeded(let actual, let budget):
      "The build took \(actual) ms, exceeding the configured \(budget) ms budget."
    case .missingBuildOutput:
      "No .robin/build output exists; run `robin build` first."
    case .outputEscapesRobinRoot:
      "Build and export paths must remain inside the project's .robin directory."
    }
  }
}

package struct RobinCommandRunner {
  @discardableResult
  package static func run(
    _ command: RobinCommand,
    at projectRoot: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  ) throws -> [ToolDiagnostic] {
    switch command {
    case .initialize(let name, let template, let templatesDirectory):
      _ = try ProjectScaffolder.create(
        name: name,
        template: template,
        templatesDirectory: templatesDirectory,
        projectRoot: projectRoot
      )
      return []
    case .dev:
      try execute("swift", ["run"], at: projectRoot)
      return []
    case .build:
      let policy = try ToolPolicyLoader.load(at: projectRoot)
      let start = DispatchTime.now().uptimeNanoseconds
      try execute(
        "swift", ["run", "-c", "release"],
        at: projectRoot, environment: ["ROBIN_BUILD": "1"])
      if let budget = policy?.buildBudgetMilliseconds {
        try validateBuildDuration(
          milliseconds: Int((DispatchTime.now().uptimeNanoseconds - start) / 1_000_000),
          budget: budget
        )
      }
      return []
    case .serve:
      try execute("swift", ["run", "-c", "release"], at: projectRoot)
      return []
    case .worker:
      try execute("swift", ["run", "-c", "release", "--", "worker"], at: projectRoot)
      return []
    case .test:
      try execute("swift", ["test"], at: projectRoot)
      return []
    case .export:
      let layout = OutputLayout(projectRoot: projectRoot)
      let source = layout.path(for: .build)
      let destination = layout.path(for: .export)
      guard layout.contains(source), layout.contains(destination) else {
        throw RobinCommandRunnerError.outputEscapesRobinRoot
      }
      guard FileManager.default.fileExists(atPath: source.path) else {
        throw RobinCommandRunnerError.missingBuildOutput
      }
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: source, to: destination)
      return []
    case .lint(let json):
      var diagnostics = ProjectLinter.lint(at: projectRoot)
      do {
        try execute(
          "swift",
          [
            "format", "lint", "--strict", "--recursive", "--parallel", "Sources", "Tests",
            "Package.swift",
          ],
          at: projectRoot,
          suppressingOutput: json
        )
      } catch RobinCommandRunnerError.commandFailed {
        diagnostics.append(
          .init(
            code: "swift-format",
            severity: .error,
            message: "Swift source formatting does not pass strict validation.",
            remediation:
              "Run `swift format format --in-place --recursive Sources Tests Package.swift`."
          ))
      }
      if try ToolPolicyLoader.load(at: projectRoot)?.lintSeverity == .error {
        diagnostics = diagnostics.map { diagnostic in
          guard diagnostic.severity == .warning else { return diagnostic }
          return ToolDiagnostic(
            code: diagnostic.code,
            severity: .error,
            message: diagnostic.message,
            location: diagnostic.location,
            remediation: diagnostic.remediation
          )
        }
      }
      return diagnostics
    case .doctor:
      var diagnostics = ProjectDoctor.diagnose(at: projectRoot)
      do {
        try execute(
          "swift", ["package", "show-dependencies", "--format", "json"],
          at: projectRoot, suppressingOutput: true)
      } catch RobinCommandRunnerError.commandFailed {
        diagnostics.append(
          .init(
            code: "dependency-resolution",
            severity: .error,
            message: "SwiftPM could not resolve the dependency graph.",
            remediation: "Run `swift package resolve` and address the reported dependency error."
          ))
      }
      return diagnostics
    }
  }

  package static func validateBuildDuration(milliseconds: Int, budget: Int) throws {
    guard milliseconds <= budget else {
      throw RobinCommandRunnerError.buildBudgetExceeded(
        actualMilliseconds: milliseconds,
        budgetMilliseconds: budget
      )
    }
  }

  private static func execute(
    _ executable: String,
    _ arguments: [String],
    at directory: URL,
    suppressingOutput: Bool = false,
    environment: [String: String] = [:]
  ) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = directory
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
    if suppressingOutput {
      process.standardOutput = FileHandle.nullDevice
      process.standardError = FileHandle.nullDevice
    }
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw RobinCommandRunnerError.commandFailed(executable, process.terminationStatus)
    }
  }
}
