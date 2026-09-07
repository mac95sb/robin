import Foundation
import RobinAuth
import RobinBuild
import RobinCore
import RobinData
import RobinHTML
import RobinServer
import RobinStyle

/// A localized workspace with authenticated notes and realtime conversations.
@main
struct Site: App {
  var resourceBundle: Bundle? { .module }

  var theme: any ApplicationTheme { Theme.starter }

  static let port = ServerAddress.environment.port
  static let origin = URL(string: "http://localhost:\(port)")!
  static let allowedOrigins: Set<String> = [origin.absoluteString]
  private let notes: NotesStore
  private let services: DashboardServices

  var middleware: [Middleware] {
    [
      .security(.init(allowedOrigins: Self.allowedOrigins, requestsPerMinute: 120)),
      .authSessions(services.sessions, store: services.authentication),
      pageServices,
    ]
  }

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
        url: "/social-card.jpg",
        alternativeText: "__PROJECT__ dashboard preview",
        width: 1200,
        height: 630,
        mediaType: "image/jpeg"),
      author: .init("__PROJECT__ Team"),
      publisher: .init("__PROJECT__"),
      icons: [.init(url: "/favicon.png", mediaType: "image/png")],
      structuredData: [
        .softwareApplication(.init(operatingSystem: "Any", category: "BusinessApplication"))
      ])
  }

  @PagesBuilder var pages: PageList {
    DashboardPage()
    NotesPage()
    ChatPage()
  }

  @RoutesBuilder var routes: RouteList {
    AppController(notes: notes)
    ChatController(messages: services.messages, usernames: services.usernames)
    ProfileController(usernames: services.usernames)
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
        try SitePreferencesClientModule.asset(), try passkeyClient.asset(),
        try FormSubmissionClientModule(regionID: "notes", actionPrefix: "/api/v1/notes").asset(),
        try WebSocketClientModule(
          path: "/api/v1/chat", formID: "chat-form", inputID: "chat-input",
          messagesID: "chat-messages", statusID: "chat-status", messageFormat: .json
        ).asset(),
      ],
      middleware: site.middleware,
      onShutdown: services.shutdown)
  }
}
