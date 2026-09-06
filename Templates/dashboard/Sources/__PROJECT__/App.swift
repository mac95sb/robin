import Foundation
import RobinAuth
import RobinBuild
import RobinContent
import RobinCore
import RobinData
import RobinHTML
import RobinServer
import RobinStyle

@main
struct Site: App {
  var theme: any ApplicationTheme { Theme.starter }

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
      icons: [.init(url: "/favicon.png", mediaType: "image/png")],
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
      NotesPage()
      ChatPage()
    }
  }

  @RoutesBuilder var routes: RouteList {
    AppController(notes: notes)
    ChatController(messages: services.messages, usernames: services.usernames)
    UsernameController(usernames: services.usernames)
    PasskeyController(passkeys: services.passkeys, sessions: services.sessions)
  }

  var pageServices: Middleware {
    .requestServices { request, context in
      let conversations = request.path.split(separator: "/").last == "conversations"
      let notes: [Note] =
        if request.path.split(separator: "/").last == "notes", let ownerID = context.principal?.id {
          try await self.notes.all(ownerID: ownerID)
        } else {
          []
        }
      let names =
        context.principal == nil || !conversations ? [:] : try await services.usernames.all()
      return context.services
        .setting(SignedInKey.self, to: context.principal != nil)
        .setting(NoteListKey.self, to: notes)
        .setting(UsernameKey.self, to: context.principal.flatMap { names[$0.id] })
        .setting(AuthorNamesKey.self, to: names)
        .setting(
          MessageListKey.self,
          to: context.principal == nil || !conversations ? [] : try await services.messages.all())
    }
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
      assets: [
        try BuildAsset(
          reference: "/favicon.png", path: "assets/favicon.png",
          bytes: Array(
            try Data(contentsOf: Bundle.module.url(forResource: "favicon", withExtension: "png")!)),
          mediaType: "image/png"),
        try SitePreferencesClientModule.asset(), try passkeyClient.asset(),
        try FormSubmissionClientModule(regionID: "notes", actionPrefix: "/api/v1/notes").asset(),
        try WebSocketClientModule(
          path: "/api/v1/chat", formID: "chat-form", inputID: "chat-input",
          messagesID: "chat-messages", statusID: "chat-status", messageFormat: .json
        ).asset(),
      ],
      address: .init(host: "127.0.0.1", port: port),
      middleware: [
        .security(.init(allowedOrigins: allowedOrigins, requestsPerMinute: 120)),
        .authSessions(services.sessions, store: services.authentication),
        site.pageServices,
      ],
      onShutdown: services.shutdown)
  }
}
