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
    #expect(package.contains("https://github.com/mac95sb/robin.git"))
    #expect(!package.contains(#".package(path: "../..")"#))
    #expect(
      !FileManager.default.fileExists(atPath: destination.appendingPathComponent(".build").path))
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Package.resolved").path))
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
    if template == .api {
      #expect(!app.contains("metadata"))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/ProjectController.swift"), encoding: .utf8)
      #expect(controller.contains("RouteDefinition.path"))
      #expect(!controller.contains("RouteDefinition<Int>"))
      #expect(controller.contains("struct ProjectController: Controller"))
      #expect(controller.contains("let route = \"projects\""))
      #expect(!controller.contains("RouteDefinition<Void>"))
    } else {
      #expect(app.contains("LocalizedPages("))
      #expect(app.contains("bundle: .module"))
      #expect(app.contains("separator: \" — \""))
      #expect(!app.contains("openGraph:"))
      #expect(app.contains("structuredData"))
      let localization = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Resources/Localizable.xcstrings"),
        encoding: .utf8)
      #expect(localization.contains("\"sourceLanguage\" : \"en\""))
      #expect(
        !FileManager.default.fileExists(
          atPath: destination.appendingPathComponent(
            "Sources/Example/SiteLocalization.swift"
          ).path))
    }
    if template == .api {
      #expect(app.contains("RouteGroup("))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/HealthController.swift"), encoding: .utf8)
      #expect(controller.contains("let route = \"health\""))
      #expect(!controller.contains("typealias"))
    } else if template == .ssr {
      #expect(app.contains("AppController(notes: notes)"))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/AppController.swift"), encoding: .utf8)
      #expect(controller.contains("struct AppController: Controller"))
      #expect(controller.contains("RouteDefinition.path(\"system\", \"health\")"))
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
