import ArgumentParser
import Foundation
import Noora
import RobinTooling

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
public struct RobinCommandLine: AsyncParsableCommand {
  public static let configuration = CommandConfiguration(
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

  public init() {}

  static var terminal: Noora {
    Noora(standardPipelines: .init(output: StandardErrorPipeline()))
  }

  static func run(_ command: RobinCommand, additionalDiagnostics: [ToolDiagnostic] = [])
    async throws
  {
    let noora = RobinCommandLine.terminal
    let json = emitsJSON(command)
    let showsProgress: Bool
    switch command {
    case .initialize, .export, .doctor: showsProgress = !json && Terminal.isInteractive()
    default: showsProgress = false
    }
    if !json && !showsProgress {
      noora.info(.alert(TerminalText(stringLiteral: command.startMessage)))
    }
    let diagnostics: [ToolDiagnostic]
    do {
      if showsProgress {
        diagnostics = try await noora.progressStep(
          message: command.startMessage,
          successMessage: "\(command.displayName) finished; reviewing results.",
          errorMessage: "\(command.displayName) could not complete.", showSpinner: true
        ) { _ in
          try RobinCommandRunner.run(command, additionalDiagnostics: additionalDiagnostics)
        }
      } else {
        diagnostics = try RobinCommandRunner.run(
          command, additionalDiagnostics: additionalDiagnostics)
        if command == .dev {
          try await RobinCommandRunner.serveStaticBuildIfPresent()
        }
      }
    } catch {
      let failure = ToolDiagnostic(
        code: "command-failed", severity: .error,
        message: "\(command.displayName) could not complete: \(error)",
        remediation: "Address the reported error and run the command again.")
      if json {
        try writeJSON([failure])
      } else {
        print(failure, using: noora)
      }
      throw ExitCode.failure
    }
    if json {
      try writeJSON(diagnostics)
    } else {
      let rows = diagnostics.compactMap { diagnostic -> [String]? in
        guard let metric = diagnostic.measurement else { return nil }
        return [
          diagnostic.message, metric.value.formatted(.number.precision(.fractionLength(0...3))),
          metric.unit,
        ]
      }
      if !rows.isEmpty { noora.table(headers: ["Metric", "Value", "Unit"], rows: rows) }
      for diagnostic in diagnostics where diagnostic.measurement == nil {
        print(diagnostic, using: noora)
      }
      let summary = command.summary(diagnostics: diagnostics)
      let message = TerminalText(stringLiteral: summary.message)
      let takeaways = summary.takeaways.map { TerminalText(stringLiteral: $0) }
      switch summary.severity {
      case .note: noora.success(.alert(message, takeaways: takeaways))
      case .warning: noora.warning(.alert(message, takeaway: takeaways.first))
      case .error: noora.error(.alert(message, takeaways: takeaways))
      }
    }
    if diagnostics.contains(where: { $0.severity == .error }) { throw ExitCode.failure }
  }

  private static func writeJSON(_ diagnostics: [ToolDiagnostic]) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    FileHandle.standardOutput.write(try encoder.encode(diagnostics))
    FileHandle.standardOutput.write(Data("\n".utf8))
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

struct InitCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "init",
    abstract: "Create a Robin project."
  )

  @Argument(help: "The project name. Omit for guided setup in a terminal.") var projectName: String?
  @Option(name: .shortAndLong, help: "The project template.")
  var template = ProjectTemplate.dashboard
  @Option(name: .customLong("site-url"), help: "The public URL for a marketing site.")
  var siteURL: String?
  @Option(name: .customLong("templates"), help: "A custom templates directory.")
  var templatesDirectory: String?

  mutating func run() async throws {
    if projectName == nil {
      guard Terminal.isInteractive() else {
        throw ValidationError("Provide a project name: robin init MySite --template blog")
      }
      let noora = RobinCommandLine.terminal
      projectName = noora.textPrompt(title: "New project", prompt: "Project name")
      let selected = noora.singleChoicePrompt(
        title: "Template", question: "What would you like to build?",
        options: ProjectTemplate.allCases.map(\.rawValue))
      template = ProjectTemplate(rawValue: selected) ?? .dashboard
    }
    guard let projectName else { throw ValidationError("A project name is required.") }
    try await RobinCommandLine.run(
      .initialize(
        name: projectName,
        template: template,
        siteURL: siteURL,
        templatesDirectory: templatesDirectory.map { URL(fileURLWithPath: $0) }
      ))
  }
}

struct DevCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dev", abstract: "Build and run the development application. Press Ctrl-C to stop."
  )
  mutating func run() async throws { try await RobinCommandLine.run(.dev) }
}

struct BuildCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "build", abstract: "Build production output in .robin/build.")
  @Flag(name: .customLong("no-optim"), help: "Skip asset transforms and CSS minification.")
  var noOptim = false

  mutating func run() async throws {
    try await RobinCommandLine.run(.build(optimizesAssets: !noOptim))
  }
}

struct ExportCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "export",
    abstract: "Copy existing build output to .robin/export. Replaces the previous export.")
  mutating func run() async throws { try await RobinCommandLine.run(.export) }
}

struct ServeCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "serve",
    abstract: "Build and run the production application. Press Ctrl-C to stop.")
  mutating func run() async throws { try await RobinCommandLine.run(.serve) }
}

struct WorkerCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "worker",
    abstract: "Run the application’s background worker. Press Ctrl-C to stop.")
  mutating func run() async throws { try await RobinCommandLine.run(.worker) }
}

struct TestCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "test", abstract: "Run the project’s Swift tests.")
  mutating func run() async throws { try await RobinCommandLine.run(.test) }
}

extension PageSpeedAudit.Strategy: ExpressibleByArgument {}

struct LintCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "lint",
    abstract: "Check project conventions, formatting, and built artifact sizes.",
    discussion:
      "Use --url for an optional Google PageSpeed Insights audit. Set PAGESPEED_API_KEY for API quota. Errors exit with status 1; warnings follow robin.pkl policy."
  )
  @Flag(help: "Emit JSON diagnostics only, including numeric measurements.") var json = false
  @Option(help: "Public HTTP(S) URL to audit with PageSpeed Insights.") var url: String?
  @Option(help: "PageSpeed device strategy: mobile or desktop.") var strategy = PageSpeedAudit
    .Strategy.mobile

  mutating func validate() throws {
    if let url {
      do { _ = try PageSpeedAudit.request(url: url, strategy: strategy, key: nil) } catch {
        throw ValidationError("--url must be an HTTP(S) URL with a host and no credentials.")
      }
    }
  }

  mutating func run() async throws {
    var remote: [ToolDiagnostic] = []
    if let url {
      if !json {
        RobinCommandLine.terminal.info(.alert("Auditing the public URL with PageSpeed Insights…"))
      }
      remote = await PageSpeedAudit.audit(url: url, strategy: strategy)
    }
    try await RobinCommandLine.run(.lint(json: json), additionalDiagnostics: remote)
  }
}

struct DoctorCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "doctor",
    abstract: "Check required tools, project configuration, and dependency resolution.")
  @Flag(help: "Emit JSON diagnostics.") var json = false
  mutating func run() async throws { try await RobinCommandLine.run(.doctor(json: json)) }
}
