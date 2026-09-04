import Foundation
import RobinCore
import Testing

@testable import RobinTooling

@Suite("Project diagnostics")
struct ProjectDiagnosticsTests {
  @Test func lintFindingsAreStructuredSourceLocatedAndActionable() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Sources/App"), withIntermediateDirectories: true)
    try Data(
      "let page = RawHTML()\nlet old = FeatureFlag(\"old\", default: false, removalDate: .distantPast)\nlet fixed = FeatureFlag(\"fixed\", default: true, fixedValueSince: .distantPast)"
        .utf8
    ).write(
      to: root.appendingPathComponent("Sources/App/App.swift"))
    try Data(".build/\n".utf8).write(to: root.appendingPathComponent(".gitignore"))

    let findings = ProjectLinter.lint(at: root)

    #expect(findings.contains { $0.code == "raw-web-escape-hatch" && $0.location != nil })
    #expect(findings.contains { $0.code == "generated-output-not-ignored" })
    #expect(findings.contains { $0.code == "stale-feature-flag" && $0.location?.line == 2 })
    #expect(findings.contains { $0.code == "stale-feature-flag" && $0.location?.line == 3 })
    #expect(findings.allSatisfy { $0.remediation != nil })
    #expect(try JSONEncoder().encode(findings).isEmpty == false)
  }

  @Test func applicationModelIsNotMistakenForAnApplicationModeSetting() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Sources/App"), withIntermediateDirectories: true)
    try Data("let applicationModel = \"shared\"".utf8).write(
      to: root.appendingPathComponent("Sources/App/App.swift"))

    #expect(!ProjectLinter.lint(at: root).contains { $0.code == "manual-application-mode" })
  }

  @Test func exportCopiesOnlyRobinBuildOutput() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let layout = OutputLayout(projectRoot: root)
    let build = layout.path(for: .build)
    try FileManager.default.createDirectory(at: build, withIntermediateDirectories: true)
    try Data("artifact".utf8).write(to: build.appendingPathComponent("index.html"))

    _ = try RobinCommandRunner.run(.export, at: root)

    #expect(
      try Data(contentsOf: layout.path(for: .export).appendingPathComponent("index.html"))
        == Data("artifact".utf8))
  }

  @Test func doctorReportsTheDetectedStableCompiler() {
    let diagnostics = ProjectDoctor.diagnose(
      at: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
      environment: [:]
    )
    #expect(
      diagnostics.contains {
        $0.code == "swift-version" && $0.severity == .note && $0.message.contains("6.3.3")
      })
  }

  @Test func doctorIncludesExpiredFeatureFlagDiagnostics() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Sources/App"), withIntermediateDirectories: true)
    try Data(
      "let old = FeatureFlag(\"old\", default: false, removalDate: .distantPast)".utf8
    ).write(to: root.appendingPathComponent("Sources/App/App.swift"))

    #expect(ProjectDoctor.diagnose(at: root).contains { $0.code == "stale-feature-flag" })
  }
}
