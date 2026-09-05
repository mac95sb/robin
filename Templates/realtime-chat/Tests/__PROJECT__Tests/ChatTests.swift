import HTTPTypes
import RobinAuth
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func chatPageHasNoStructuralAccessibilityFindings() {
  #expect(AccessibilityAudit.audit(ChatPage()).isEmpty)
}

@Test func authenticatedMessagesPersistAndSocketRequiresWebSockets() async throws {
  let services = try await ChatServices()
  let messages = MessageStore(services.storage)
  let account = try Account(id: "demo", name: "Demo")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let site = Site(messages: messages, services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .security(.init(allowedOrigins: Site.allowedOrigins)),
      .authSessions(services.sessions, store: services.authentication),
      .requestServices { _, context in
        context.services.setting(
          MessageListKey.self,
          to: context.principal == nil ? [] : try await messages.all())
      },
    ],
    transportCapabilities: .persistent)
  let headers: HTTPFields = [
    .cookie: "robin-session=\(token.value)", .origin: Site.origin.absoluteString,
  ]

  _ = try await messages.append("Hello", authorID: account.id)
  let history = await responder.respond(
    to: Request(
      .init(
        method: .get, scheme: nil, authority: nil, path: "/api/v1/messages",
        headerFields: headers)))
  #expect(history.head.status == .ok)

  let page = await responder.respond(
    to: Request(
      .init(method: .get, scheme: nil, authority: nil, path: "/en", headerFields: headers)))
  #expect(String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self).contains("Hello"))

  let socket = await responder.respond(
    to: Request(
      .init(
        method: .get, scheme: nil, authority: nil, path: "/api/v1/chat",
        headerFields: headers)))
  guard case .webSocket = socket.body else {
    let body = String(decoding: socket.body.bufferedBytes ?? [], as: UTF8.self)
    Issue.record("Expected a WebSocket session, received HTTP \(socket.head.status.code): \(body)")
    try await services.shutdown()
    return
  }

  var hostileHeaders = headers
  hostileHeaders[.origin] = "https://attacker.example"
  let hostile = await responder.respond(
    to: Request(
      .init(
        method: .get, scheme: nil, authority: nil, path: "/api/v1/chat",
        headerFields: hostileHeaders)))
  #expect(hostile.head.status == .forbidden)
  try await services.shutdown()
}

@Test func messageHistoryIsBounded() async throws {
  let services = try await ChatServices()
  let messages = MessageStore(services.storage)
  for number in 0...MessageStore.maximumMessages {
    _ = try await messages.append("Message \(number)", authorID: "demo")
  }
  #expect(try await messages.all().count == MessageStore.maximumMessages)
  await #expect(throws: MessageStoreError.messageTooLarge) {
    try await messages.append(
      String(repeating: "a", count: MessageStore.maximumMessageBytes + 1), authorID: "demo")
  }
  try await services.shutdown()
}

@Test func concurrentMessagesAreNotLost() async throws {
  let services = try await ChatServices()
  let messages = MessageStore(services.storage)
  try await withThrowingTaskGroup(of: Void.self) { group in
    for number in 0..<20 {
      group.addTask { _ = try await messages.append("Message \(number)", authorID: "demo") }
    }
    try await group.waitForAll()
  }
  #expect(try await messages.all().count == 20)
  try await services.shutdown()
}

@Test func messagesReachEverySubscriberAndDisconnectFinishesTheStream() async throws {
  let services = try await ChatServices()
  let messages = MessageStore(services.storage)
  let (firstID, first) = await messages.subscribe()
  let (secondID, second) = await messages.subscribe()
  _ = try await messages.append("Hello everyone", authorID: "demo")
  await messages.unsubscribe(firstID)
  await messages.unsubscribe(secondID)
  var firstMessages: [String] = []
  for await message in first { firstMessages.append(message.text) }
  var secondMessages: [String] = []
  for await message in second { secondMessages.append(message.text) }
  #expect(firstMessages == ["Hello everyone"])
  #expect(secondMessages == firstMessages)
  try await services.shutdown()
}
