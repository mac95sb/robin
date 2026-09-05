import ArgumentParser
import Foundation
import Testing

@testable import RobinCLI
@testable import RobinTooling

@Suite("Robin command-line parsing")
struct CommandLineParserTests {
  @Test func defaultsInitToSSRAndAcceptsOnlyThreeTemplates() throws {
    let defaults = try #require(
      try RobinCommandLine.parseAsRoot(["init", "Example"]) as? InitCommand)
    #expect(defaults.projectName == "Example")
    #expect(defaults.template == .dashboard)
    #expect(defaults.templatesDirectory == nil)

    let configured = try #require(
      try RobinCommandLine.parseAsRoot([
        "init", "Example", "-t", "blog", "--templates", "/tmp/templates",
      ]) as? InitCommand)
    #expect(configured.template == .blog)
    #expect(configured.templatesDirectory == "/tmp/templates")

    #expect(throws: (any Error).self) {
      try RobinCommandLine.parseAsRoot(["init", "Example", "-t", "hybrid"])
    }
  }

  @Test func parsesEveryCommandAndMachineReadableDiagnostics() throws {
    #expect(try RobinCommandLine.parseAsRoot(["dev"]) is DevCommand)
    #expect(try RobinCommandLine.parseAsRoot(["build"]) is BuildCommand)
    #expect(try RobinCommandLine.parseAsRoot(["export"]) is ExportCommand)
    #expect(try RobinCommandLine.parseAsRoot(["serve"]) is ServeCommand)
    #expect(try RobinCommandLine.parseAsRoot(["worker"]) is WorkerCommand)
    #expect(try RobinCommandLine.parseAsRoot(["test"]) is TestCommand)
    let lint = try #require(
      try RobinCommandLine.parseAsRoot(["lint", "--json"]) as? LintCommand)
    #expect(lint.json)
    let doctor = try #require(
      try RobinCommandLine.parseAsRoot(["doctor"]) as? DoctorCommand)
    #expect(!doctor.json)
  }
}
