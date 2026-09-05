import Foundation
import RobinAuth
import RobinContent
import RobinCore
import RobinData
import RobinHTML
import RobinServer

@main
struct Site: App {
  static let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080
  static let origin = URL(string: "http://localhost:\(port)")!
  static let allowedOrigins: Set<String> = [origin.absoluteString]
  private let notes: NotesStore
  private let services: DashboardServices

  init(services: DashboardServices) {
    self.services = services
    self.notes = NotesStore(services.storage)
  }

  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "A localized server-rendered Robin application.",
      image: .init(
        url: "https://example.com/social-card.png",
        alternativeText: "__PROJECT__ dashboard preview"),
      author: .init("__PROJECT__ Team"),
      publisher: .init("__PROJECT__"),
      structuredData: [
        .softwareApplication(.init(operatingSystem: "Any", category: "BusinessApplication"))
      ])
  }

  @PagesBuilder var pages: PageList {
    LocalizedPages(
      bundle: .module,
      baseURL: URL(string: "https://example.com")!
    ) {
      DashboardPage()
      AboutPage()
    }
  }

  @RoutesBuilder var routes: RouteList {
    AppController(notes: notes)
    PasskeyController(passkeys: services.passkeys, sessions: services.sessions)
  }

  static func main() async throws {
    let directory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0].appendingPathComponent("__PROJECT__", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let services = try await DashboardServices(
      storage: .file(path: directory.appendingPathComponent("dashboard.sqlite").path))
    let site = Self(services: services)

    let passkeyClient = try PasskeyClientModule(
      registration: .init(
        buttonID: "register", beginURL: "/api/v1/auth/register/begin",
        finishURL: "/api/v1/auth/register/finish"),
      authentication: .init(
        buttonID: "login", beginURL: "/api/v1/auth/login/begin",
        finishURL: "/api/v1/auth/login/finish"),
      reloadOnCompletion: true)
    try await RobinApplication.run(
      site,
      assets: [try passkeyClient.asset()],
      address: .init(host: "127.0.0.1", port: port),
      middleware: [
        .security(.init(allowedOrigins: allowedOrigins, requestsPerMinute: 120)),
        .authSessions(services.sessions, store: services.authentication),
        .requestServices { _, context in
          let notes: [Note] =
            if let ownerID = context.principal?.id {
              try await site.notes.all(ownerID: ownerID)
            } else {
              []
            }
          return context.services.setting(NoteListKey.self, to: notes)
        },
      ],
      onShutdown: services.shutdown)
  }
}
