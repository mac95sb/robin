import Foundation
import RobinAuth
import RobinBuild
import RobinCore
import RobinData
import RobinHTML
import RobinServer
import RobinStyle
import RobinTheme

/// An authenticated, persistent realtime chat application.
@main
struct Site: App {
  static let port = ServerAddress.environment.port
  static let origin = URL(string: "http://localhost:\(port)")!
  private let services: ChatServices

  init(services: ChatServices) { self.services = services }

  var theme: any ApplicationTheme { Theme.robin }
  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "An authenticated, persistent realtime chat application.",
      structuredData: [
        .softwareApplication(.init(operatingSystem: "Any", category: "CommunicationApplication"))
      ]
    )
  }

  @PagesBuilder var pages: PageList { ChatPage() }

  @RoutesBuilder var routes: RouteList {
    ChatController(messages: services.messages)
    PasskeyController(passkeys: services.passkeys, sessions: services.sessions)
  }

  var middleware: [Middleware] {
    [
      .security(.init(allowedOrigins: [Self.origin.absoluteString], requestsPerMinute: 120)),
      .authSessions(services.sessions, store: services.authentication),
      .requestServices { _, context in
        context.services
          .setting(SignedInKey.self, to: context.principal != nil)
          .setting(
            MessageListKey.self,
            to: context.principal == nil ? [] : try await services.messages.all()
          )
      },
    ]
  }

  static func main() async throws {
    let directory =
      FileManager.default
      .urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      )[0]
      .appendingPathComponent("__PROJECT__", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let services = try await ChatServices(
      storage: .file(path: directory.appendingPathComponent("chat.sqlite").path)
    )
    let site = Self(services: services)
    let passkeys = try PasskeyClientModule(
      registration: .init(
        buttonID: "register",
        beginURL: "/api/v1/auth/register/begin",
        finishURL: "/api/v1/auth/register/finish"
      ),
      authentication: .init(
        buttonID: "login",
        beginURL: "/api/v1/auth/login/begin",
        finishURL: "/api/v1/auth/login/finish"
      ),
      reloadOnCompletion: true
    )
    try await RobinApplication.run(
      site,
      assets: [
        try passkeys.asset(),
        try WebSocketClientModule(
          path: "/api/v1/chat",
          formID: "chat-form",
          inputID: "chat-input",
          messagesID: "chat-messages",
          statusID: "chat-status",
          messageFormat: .json
        )
        .asset(),
      ],
      middleware: site.middleware,
      onShutdown: services.shutdown
    )
  }
}
