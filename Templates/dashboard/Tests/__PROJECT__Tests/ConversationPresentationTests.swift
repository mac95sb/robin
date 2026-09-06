import HTTPTypes
import RobinAuth
import RobinServer
import Testing

@testable import __PROJECT__

@Test func conversationControlsFollowTheAuthenticatedSession() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "presentation", name: "Presentation")
  try await services.authentication.save(account)
  try await services.usernames.set("tester", for: account.id)
  let token = try await services.sessions.create(for: account.id)
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .authSessions(services.sessions, store: services.authentication),
      site.pageServices,
    ],
    transportCapabilities: .persistent)

  for signedIn in [false, true] {
    let headers: HTTPFields = signedIn ? [.cookie: "robin-session=\(token.value)"] : [:]
    let response = await responder.respond(
      to: Request(
        .init(
          method: .get, scheme: nil, authority: nil, path: "/en/conversations",
          headerFields: headers)))
    #expect(response.head.status == .ok)
    let html = String(decoding: response.body.bufferedBytes ?? [], as: UTF8.self)
    #expect(html.contains("/api/v1/auth/logout") == signedIn)
    #expect(html.contains("Your workspace") == !signedIn)
    #expect(html.contains("Sign in to manage your notes and join the conversation.") == !signedIn)
    #expect(html.contains("id=\"register\"") == !signedIn)
    #expect(html.contains("id=\"login\"") == !signedIn)
    #expect(html.contains("id=\"chat-form\"") == signedIn)
    #expect(html.contains("id=\"chat-messages\"") == signedIn)
    #expect(html.contains("id=\"chat-status\"") == signedIn)
    #expect(html.contains("Your shared conversation") == signedIn)
  }
  try await services.shutdown()
}
