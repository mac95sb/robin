import Testing

@testable import RobinTooling

@Suite("Command output")
struct CommandOutputTests {
  @Test func lintReportsCheckOutcomeRatherThanProcessSuccess() {
    let lint = RobinCommand.lint(json: false)
    #expect(lint.summary(diagnostics: []).message == "Lint passed: 0 errors, 0 warnings.")
    let warning = ToolDiagnostic(code: "example", severity: .warning, message: "Review this.")
    #expect(lint.summary(diagnostics: [warning]).severity == .warning)
    let error = ToolDiagnostic(code: "example", severity: .error, message: "Fix this.")
    let failed = lint.summary(diagnostics: [warning, error])
    #expect(failed.severity == .error)
    #expect(failed.message == "Lint failed: 1 error, 1 warning.")
    let note = ToolDiagnostic(code: "version", severity: .note, message: "Swift detected.")
    #expect(
      RobinCommand.doctor(json: false).summary(diagnostics: [note]).message
        == "Environment checks passed: 0 errors, 0 warnings.")
  }

  @Test func creationAndExportDescribeActualWork() {
    let created = RobinCommand.initialize(name: "MySite", template: .blog, templatesDirectory: nil)
      .summary(diagnostics: [])
    #expect(created.takeaways.contains("cd MySite"))
    #expect(created.takeaways.contains("robin dev"))
    #expect(created.message.contains("blog"))
    #expect(
      RobinCommand.export.summary(diagnostics: []).takeaways.first?.contains("does not rebuild")
        == true)
  }
}
