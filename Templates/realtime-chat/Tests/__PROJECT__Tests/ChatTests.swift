import HTTPTypes
import RobinAuth
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func chatPageIsAccessible() {
  #expect(AccessibilityAudit.audit(ChatPage()).isEmpty)
}

@Test func authenticatedMessagesPersistAndSocketRequiresWebSockets() async throws {
  let services = try await ChatServices()
  let account = try Account(id: "demo", name: "Demo")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: site.middleware,
    transportCapabilities: .persistent
  )
  let headers: HTTPFields = [
    .cookie: "robin-session=\(token.value)", .origin: Site.origin.absoluteString,
  ]

  _ = try await services.messages.append("Hello", authorID: account.id)
  let page = await responder.respond(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/", headerFields: headers))
  )
  #expect(String(decoding: page.body.bufferedBytes ?? [], as: UTF8.self).contains("Hello"))

  let socket = await responder.respond(
    to: Request(
      .init(method: .get, scheme: nil, authority: nil, path: "/api/v1/chat", headerFields: headers)
    )
  )
  guard case .webSocket = socket.body else {
    Issue.record("Expected a WebSocket session, received HTTP \(socket.head.status.code)")
    try await services.shutdown()
    return
  }
  try await services.shutdown()
}

@Test func messagesReachSubscribersAndRejectOversizedInput() async throws {
  let services = try await ChatServices()
  let (id, stream) = await services.messages.subscribe()
  _ = try await services.messages.append("Hello", authorID: "demo")
  await services.messages.unsubscribe(id)
  var received: [String] = []
  for await message in stream { received.append(message.text) }
  #expect(received == ["Hello"])
  await #expect(throws: MessageStoreError.messageTooLarge) {
    try await services.messages.append(
      String(repeating: "a", count: MessageStore.maximumMessageBytes + 1),
      authorID: "demo"
    )
  }
  try await services.shutdown()
}
