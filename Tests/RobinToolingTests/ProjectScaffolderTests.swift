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
      siteURL: template == .marketing ? "https://example.com" : nil,
      templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
      projectRoot: root
    )

    #expect(
      FileManager.default.fileExists(atPath: destination.appendingPathComponent(".gitignore").path))
    #expect(
      FileManager.default.fileExists(atPath: destination.appendingPathComponent("AGENTS.md").path))
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent(".swift-format").path))
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent(".github/workflows/documentation.yml").path))
    let mise = try String(
      contentsOf: destination.appendingPathComponent("mise.toml"), encoding: .utf8)
    #expect(mise.contains("[tasks.docs]"))
    let package = try String(
      contentsOf: destination.appendingPathComponent("Package.swift"), encoding: .utf8)
    #expect(package.contains("name: \"Example\""))
    #expect(!package.contains("__PROJECT__"))
    #expect(package.contains("https://github.com/mac95sb/robin.git"))
    #expect(package.contains("https://github.com/swiftlang/swift-docc-plugin.git"))
    #expect(package.contains("RobinTheme"))
    #expect(!package.contains(#".package(name: "robin", path: "../..")"#))
    #expect(
      !FileManager.default.fileExists(atPath: destination.appendingPathComponent(".build").path))
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Package.resolved").path))
    let app = try String(
      contentsOf: destination.appendingPathComponent("Sources/Example/App.swift"), encoding: .utf8)
    #expect(!app.contains("applicationMode"))
    #expect(app.contains("@main"))
    #expect(app.contains(template == .apiService ? "struct API: App" : "struct Site: App"))
    #expect(app.contains("RobinApplication"))
    #expect(app.contains(".run("))
    #expect(app.contains("Theme.robin"))
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Sources/Example/RobinMain.swift").path
      ))
    if template == .blank {
      let sourceRoot = destination.appendingPathComponent("Sources/Example")
      for path in [
        "App.swift",
        "Controllers/MessageController.swift",
        "Models/Message.swift",
        "Views/Pages/HomePage.swift",
      ] {
        #expect(
          FileManager.default.fileExists(atPath: sourceRoot.appendingPathComponent(path).path))
      }
      #expect(!app.contains("LocalizedPages("))
    } else if template == .marketing {
      let homePage = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Views/Pages/HomePage.swift"), encoding: .utf8)
      #expect(homePage.contains("https://example.com/docs/"))
      #expect(!homePage.contains("robin.maclong.dev"))
      #expect(!app.contains("ClientModule"))
      #expect(app.contains("robin-logo.png"))
    } else if template == .apiService {
      #expect(!app.contains("metadata"))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/TodoController.swift"), encoding: .utf8)
      #expect(controller.contains("RouteGroup(\"todos\")"))
      #expect(controller.contains("actor TodoController: Controller"))
      #expect(controller.contains("GET { _, _ in await self.list() }"))
      #expect(controller.contains("GET(\":id\")"))
      #expect(controller.contains("POST(Todo.self)"))
    } else if template == .dashboard || template == .blog {
      #expect(!app.contains("LocalizedPages("))
      #expect(app.contains("separator: \" — \""))
      #expect(!app.contains("openGraph:"))
      if template != .blog { #expect(app.contains("structuredData")) }
      let localization = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Resources/Localizable.xcstrings"),
        encoding: .utf8)
      let catalog =
        try JSONSerialization.jsonObject(with: Data(localization.utf8)) as? [String: Any]
      #expect(catalog?["sourceLanguage"] as? String == "en")
      #expect(
        !FileManager.default.fileExists(
          atPath: destination.appendingPathComponent(
            "Sources/Example/SiteLocalization.swift"
          ).path))
    }
    if template == .apiService {
      #expect(!app.contains("RouteGroup("))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/HealthController.swift"), encoding: .utf8)
      #expect(controller.contains("let prefix = \"system\""))
      #expect(controller.contains("GET(version: nil, use: health)"))
      #expect(!controller.contains("typealias"))
    } else if template == .dashboard {
      #expect(app.contains("AppController(notes: notes)"))
      #expect(
        app.contains("ChatController(messages: services.messages, usernames: services.usernames)"))
      #expect(app.contains("ChatPage()"))
      #expect(app.contains("WebSocketClientModule("))
      #expect(!app.contains("FormSubmissionClientModule("))
      #expect(app.contains(".authSessions("))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/AppController.swift"), encoding: .utf8)
      #expect(controller.contains("struct AppController: Controller"))
      #expect(controller.contains("RouteGroup(\"system\")"))
    } else if template == .realtimeChat {
      #expect(app.contains("ChatServices"))
      #expect(app.contains("ChatPage()"))
      #expect(app.contains("WebSocketClientModule("))
      let controller = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Controllers/ChatController.swift"), encoding: .utf8)
      #expect(controller.contains("WebSocketRoute("))
      #expect(!controller.contains(": APIRoute"))
      #expect(!controller.contains(": ServerRoute"))
    } else if template == .blog {
      let post = try String(
        contentsOf: destination.appendingPathComponent(
          "Sources/Example/Models/Post.swift"), encoding: .utf8)
      #expect(post.contains("MarkdownContentParser.parse"))
      for locale in ["en", "fr"] {
        let markdown = try String(
          contentsOf: destination.appendingPathComponent(
            "Sources/Example/Resources/posts/first-post-\(locale).md"), encoding: .utf8)
        #expect(markdown.hasPrefix("---\n"))
        #expect(markdown.contains("```swift"))
      }

    }
  }

  @Test func rejectsUnsafeNamesAndExistingDestinations() throws {
    let root = temporaryDirectory()
    #expect(throws: ProjectScaffolderError.invalidProjectName("../escape")) {
      try ProjectScaffolder.create(
        name: "../escape",
        template: .dashboard,
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
        projectRoot: root
      )
    }
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Existing"), withIntermediateDirectories: true)
    #expect(throws: ProjectScaffolderError.self) {
      try ProjectScaffolder.create(
        name: "Existing",
        template: .dashboard,
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"),
        projectRoot: root
      )
    }
  }

  @Test func marketingTemplateRequiresAValidPublicSiteURL() throws {
    let root = temporaryDirectory()
    #expect(throws: ProjectScaffolderError.missingMarketingSiteURL) {
      try ProjectScaffolder.create(
        name: "Marketing", template: .marketing,
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"), projectRoot: root)
    }
    #expect(throws: ProjectScaffolderError.invalidSiteURL("ftp://example.com")) {
      try ProjectScaffolder.create(
        name: "InvalidMarketing", template: .marketing, siteURL: "ftp://example.com",
        templatesDirectory: repositoryRoot.appendingPathComponent("Templates"), projectRoot: root)
    }
  }

  @Test func findsTemplatesFromTheSourceCheckout() throws {
    let destination = try ProjectScaffolder.create(
      name: "Example",
      template: .blog,
      templatesDirectory: nil,
      projectRoot: temporaryDirectory(),
      environment: [:]
    )
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Package.swift").path))
  }

  @Test func findsTemplatesBesideTheInstalledExecutable() throws {
    let installation = temporaryDirectory()
    let template = installation.appendingPathComponent("Templates/blank")
    try FileManager.default.createDirectory(at: template, withIntermediateDirectories: true)
    try Data("bundled __PROJECT__".utf8).write(to: template.appendingPathComponent("marker.txt"))
    let destination = try ProjectScaffolder.create(
      name: "Installed",
      template: .blank,
      templatesDirectory: nil,
      projectRoot: temporaryDirectory(),
      environment: [:],
      executableURL: installation.appendingPathComponent("robin")
    )
    #expect(
      try String(contentsOf: destination.appendingPathComponent("marker.txt"), encoding: .utf8)
        == "bundled Installed")
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
