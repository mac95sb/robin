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
  private let messages: MessageStore
  private let services: ChatServices

  init(messages: MessageStore, services: ChatServices) {
    self.messages = messages
    self.services = services
  }

  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      separator: " — ",
      description: "An authenticated, persistent realtime chat built with Robin.",
      image: .init(
        url: "https://example.com/social-card.png",
        alternativeText: "__PROJECT__ chat preview"),
      author: .init("__PROJECT__ Team"),
      publisher: .init("__PROJECT__"),
      structuredData: [
        .softwareApplication(.init(operatingSystem: "Any", category: "CommunicationApplication"))
      ])
  }

  @PagesBuilder var pages: PageList {
    LocalizedPages(
      bundle: .module,
      baseURL: URL(string: "https://example.com")!
    ) {
      ChatPage()
    }
  }

  @RoutesBuilder var routes: RouteList {
    ChatController(messages: messages)
    PasskeyController(passkeys: services.passkeys, sessions: services.sessions)
  }

  static func main() async throws {
    let directory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0].appendingPathComponent("__PROJECT__", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let services = try await ChatServices(
      storage: .file(path: directory.appendingPathComponent("chat.sqlite").path))
    let site = Self(messages: MessageStore(services.storage), services: services)
    let client = try WebSocketClientModule(
      path: "/api/v1/chat",
      formID: "chat-form",
      inputID: "chat-input",
      messagesID: "chat-messages",
      statusID: "chat-status")
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
      assets: [try client.asset(), try passkeyClient.asset()],
      address: .init(host: "127.0.0.1", port: port),
      middleware: [
        .security(.init(allowedOrigins: allowedOrigins, requestsPerMinute: 120)),
        .authSessions(services.sessions, store: services.authentication),
        .requestServices { _, context in
          context.services.setting(
            MessageListKey.self,
            to: context.principal == nil ? [] : try await site.messages.all())
        },
      ],
      onShutdown: services.shutdown)
  }
}
