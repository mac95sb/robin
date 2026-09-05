import ArgumentParser
import Foundation
import Noora
import RobinTooling

@main
struct RobinCommandLine: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "robin",
    abstract: "Build and operate Robin projects.",
    subcommands: [
      InitCommand.self,
      DevCommand.self,
      BuildCommand.self,
      ExportCommand.self,
      ServeCommand.self,
      WorkerCommand.self,
      TestCommand.self,
      LintCommand.self,
      DoctorCommand.self,
    ]
  )

  static func run(_ command: RobinCommand) throws {
    let noora = Noora()
    let diagnostics = try RobinCommandRunner.run(command)
    if emitsJSON(command) {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      FileHandle.standardOutput.write(try encoder.encode(diagnostics))
      FileHandle.standardOutput.write(Data("\n".utf8))
    } else {
      for diagnostic in diagnostics { print(diagnostic, using: noora) }
      if diagnostics.isEmpty { noora.success(.alert("Robin command completed.")) }
    }
    if diagnostics.contains(where: { $0.severity == .error }) { throw ExitCode.failure }
  }

  private static func emitsJSON(_ command: RobinCommand) -> Bool {
    switch command {
    case .lint(let json), .doctor(let json): json
    default: false
    }
  }

  private static func print(_ diagnostic: ToolDiagnostic, using noora: Noora) {
    let location =
      diagnostic.location.map { " [\($0.path)\($0.line.map { ":\($0)" } ?? "")]" } ?? ""
    let message = TerminalText(
      stringLiteral: "[\(diagnostic.code)] \(diagnostic.message)\(location)")
    let takeaways = diagnostic.remediation.map { [TerminalText(stringLiteral: $0)] } ?? []
    switch diagnostic.severity {
    case .note: noora.info(.alert(message, takeaways: takeaways))
    case .warning: noora.warning(.alert(message, takeaway: takeaways.first))
    case .error: noora.error(.alert(message, takeaways: takeaways))
    }
  }
}

extension ProjectTemplate: ExpressibleByArgument {}

struct InitCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "init",
    abstract: "Create a Robin project."
  )

  @Argument(help: "The project name.") var projectName: String
  @Option(name: .shortAndLong, help: "The project template.")
  var template = ProjectTemplate.dashboard
  @Option(name: .customLong("templates"), help: "A custom templates directory.")
  var templatesDirectory: String?

  mutating func run() throws {
    try RobinCommandLine.run(
      .initialize(
        name: projectName,
        template: template,
        templatesDirectory: templatesDirectory.map { URL(fileURLWithPath: $0) }
      ))
  }
}

struct DevCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "dev")
  mutating func run() throws { try RobinCommandLine.run(.dev) }
}

struct BuildCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "build")
  mutating func run() throws { try RobinCommandLine.run(.build) }
}

struct ExportCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "export")
  mutating func run() throws { try RobinCommandLine.run(.export) }
}

struct ServeCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "serve")
  mutating func run() throws { try RobinCommandLine.run(.serve) }
}

struct WorkerCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "worker")
  mutating func run() throws { try RobinCommandLine.run(.worker) }
}

struct TestCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "test")
  mutating func run() throws { try RobinCommandLine.run(.test) }
}

struct LintCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "lint")
  @Flag(help: "Emit JSON diagnostics.") var json = false
  mutating func run() throws { try RobinCommandLine.run(.lint(json: json)) }
}

struct DoctorCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "doctor")
  @Flag(help: "Emit JSON diagnostics.") var json = false
  mutating func run() throws { try RobinCommandLine.run(.doctor(json: json)) }
}
