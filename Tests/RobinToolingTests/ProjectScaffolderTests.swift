import Foundation
import Testing

@testable import RobinTooling

@Suite("Project templates")
struct ProjectScaffolderTests {
  @Test(arguments: ProjectTemplate.allCases)
  func scaffoldsEachSupportedTemplate(_ template: ProjectTemplate) throws {
    let root = temporaryDirectory()
    let destination = try ProjectScaffolder.create(
      name: "Example",
      template: template,
      templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
      projectRoot: root
    )

    #expect(
      FileManager.default.fileExists(atPath: destination.appendingPathComponent(".gitignore").path))
    #expect(
      FileManager.default.fileExists(atPath: destination.appendingPathComponent("AGENTS.md").path))
    let package = try String(
      contentsOf: destination.appendingPathComponent("Package.swift"), encoding: .utf8)
    #expect(package.contains("name: \"Example\""))
    #expect(!package.contains("__PROJECT__"))
    let app = try String(
      contentsOf: destination.appendingPathComponent("Sources/Example/App.swift"), encoding: .utf8)
    #expect(!app.contains("applicationMode"))
    #expect(app.contains("@main"))
    #expect(app.contains("struct Site: App"))
    #expect(app.contains("RobinApplication.run(Self())"))
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Sources/Example/RobinMain.swift").path
      ))
    if template == .api { #expect(!app.contains("metadata")) }
    if template != .api { #expect(app.contains("PageGroup(")) }
    if template != .static {
      #expect(app.contains("RouteGroup("))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/HealthController.swift"), encoding: .utf8)
      #expect(controller.contains("let route = \"health\""))
      #expect(!controller.contains("typealias"))
      #expect(!controller.contains("OpenAPI"))
    }
  }

  @Test func rejectsUnsafeNamesAndExistingDestinations() throws {
    let root = temporaryDirectory()
    #expect(throws: ProjectScaffolderError.invalidProjectName("../escape")) {
      try ProjectScaffolder.create(
        name: "../escape",
        template: .ssr,
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
        projectRoot: root
      )
    }
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Existing"), withIntermediateDirectories: true)
    #expect(throws: ProjectScaffolderError.self) {
      try ProjectScaffolder.create(
        name: "Existing",
        template: .ssr,
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
        projectRoot: root
      )
    }
  }

  @Test func findsTemplatesFromTheSourceCheckout() throws {
    let destination = try ProjectScaffolder.create(
      name: "Example",
      template: .static,
      templatesDirectory: nil,
      projectRoot: temporaryDirectory(),
      environment: [:]
    )
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Package.swift").path))
  }

  private var repositoryRoot: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}
