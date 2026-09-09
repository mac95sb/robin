import Foundation
import HTTPTypes
import RobinAuth
import RobinServer
import Testing

@testable import __PROJECT__

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Test func usernamesAreValidatedAndUniqueAcrossConcurrentWriters() async throws {
  let services = try await DashboardServices()
  let first = UsernameStore(storage: services.storage)
  let second = UsernameStore(storage: services.storage)
  for invalid in ["", "ab", "two words", "<script>", "éclair", String(repeating: "a", count: 25)] {
    await #expect(throws: UsernameError.invalid) { try await first.set(invalid, for: "one") }
  }
  let winners = try await withThrowingTaskGroup(of: Bool.self) { group in
    group.addTask {
      do {
        try await first.set("Robin", for: "one")
        return true
      } catch UsernameError.taken { return false }
    }
    group.addTask {
      do {
        try await second.set("ROBIN", for: "two")
        return true
      } catch UsernameError.taken { return false }
    }
    var count = 0
    for try await won in group { if won { count += 1 } }
    return count
  }
  #expect(winners == 1)
  let names = try await first.all()
  let owner = try #require(names.first?.key)
  #expect(names[owner] == "robin")
  try await first.set("robin", for: owner)
  try await first.set("new_name", for: owner)
  #expect(try await second.all()[owner] == "new_name")
  try await services.shutdown()
}

@Test func usernameSetupGatesChatAndReplacesIDsInHistory() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "private-account-id", name: "Account")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let messages = services.messages
  _ = try await messages.append("Earlier message", authorID: account.id)
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .security(.init(allowedOrigins: Site.allowedOrigins)),
      .authSessions(services.sessions, store: services.authentication), site.pageServices,
    ],
    transportCapabilities: .persistent
  )
  let headers: HTTPFields = [
    .cookie: "robin-session=\(token.value)", .origin: Site.origin.absoluteString,
    .contentType: "application/x-www-form-urlencoded", .referer: Site.origin.absoluteString + "/en",
  ]
  let initial = await responder.respond(
    to: Request(
      .init(
        method: .get,
        scheme: nil,
        authority: nil,
        path: "/en/conversations",
        headerFields: headers
      )
    )
  )
  let initialHTML = String(decoding: initial.body.bufferedBytes ?? [], as: UTF8.self)
  #expect(initialHTML.contains("Choose your username"))
  #expect(!initialHTML.contains("id=\"chat-form\""))
  let denied = await responder.respond(
    to: Request(
      .init(
        method: .get,
        scheme: nil,
        authority: nil,
        path: "/api/v1/chat",
        headerFields: headers
      )
    )
  )
  #expect(denied.head.status == .forbidden)

  let saved = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/username",
        headerFields: headers
      ),
      body: Array("username=Alice".utf8)
    )
  )
  #expect(saved.head.status == .seeOther)
  let page = await responder.respond(
    to: Request(
      .init(
        method: .get,
        scheme: nil,
        authority: nil,
        path: "/en/conversations",
        headerFields: headers
      )
    )
  )
  let html = String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self)
  #expect(html.contains("@alice: Earlier message"))
  let stored = try #require(try await messages.all().first)
  #expect(html.contains("title=\"\(stored.timestamp)\""))
  #expect(!html.contains(account.id))
  #expect(html.contains("id=\"chat-form\""))

  try await services.usernames.set("bob", for: "another-account")
  let conflict = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/username",
        headerFields: headers
      ),
      body: Array("username=BOB".utf8)
    )
  )
  #expect(conflict.head.status == .conflict)
  #expect(try await services.usernames.all()[account.id] == "alice")
  let anonymous = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/username",
        headerFields: [
          .origin: Site.origin.absoluteString, .contentType: "application/x-www-form-urlencoded",
        ]
      ),
      body: Array("username=someone".utf8)
    )
  )
  #expect(anonymous.head.status == .unauthorized)
  try await services.shutdown()
}

@Test func liveMessagesUseTheCurrentUsername() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "private-id", name: "Account")
  try await services.authentication.save(account)
  try await services.usernames.set("alice", for: account.id)
  let token = try await services.sessions.create(for: account.id)
  let messages = services.messages
  let site = Site(services: services)
  let server = try await ServerRuntime.start(
    site,
    port: 0,
    middleware: [
      .authSessions(services.sessions, store: services.authentication), site.pageServices,
    ]
  )
  let configuration = URLSessionConfiguration.ephemeral
  configuration.timeoutIntervalForRequest = 5
  configuration.timeoutIntervalForResource = 10
  let client = URLSession(configuration: configuration)
  defer { client.invalidateAndCancel() }
  do {
    let address = try #require(await server.localAddress)
    var request = URLRequest(url: URL(string: "ws://127.0.0.1:\(address.port)/api/v1/chat")!)
    request.setValue("robin-session=\(token.value)", forHTTPHeaderField: "Cookie")
    let socket = client.webSocketTask(with: request)
    socket.resume()
    for name in ["alice", "alice_new"] {
      try await services.usernames.set(name, for: account.id)
      try await socket.send(.string("Hello"))
      let received = try await socket.receive()
      if case .string(let text) = received {
        let payload = try JSONDecoder()
          .decode(
            WebSocketClientModule.Message.self,
            from: Data(text.utf8)
          )
        #expect(payload.text == "@\(name): Hello")
        let stored = try #require(try await messages.all().last)
        #expect(payload.title == stored.timestamp)
      } else {
        Issue.record("Expected a username in the live message")
      }
    }
    socket.cancel(with: .normalClosure, reason: nil)
    try await server.shutdown()
    try await services.shutdown()
  } catch {
    try? await server.shutdown()
    try? await services.shutdown()
    throw error
  }
}

@Test func usernamesSurviveDatabaseReopen() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let path = directory.appendingPathComponent("chat.sqlite").path
  let first = try await DashboardServices(storage: .file(path: path))
  try await first.usernames.set("alice", for: "account")
  try await first.shutdown()
  let reopened = try await DashboardServices(storage: .file(path: path))
  #expect(try await reopened.usernames.all()["account"] == "alice")
  await #expect(throws: UsernameError.taken) {
    try await reopened.usernames.set("ALICE", for: "other-account")
  }
  try await reopened.shutdown()
}
