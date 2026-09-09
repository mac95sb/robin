import HTTPTypes
import RobinAuth
import RobinServer
import Testing

@testable import __PROJECT__

@Test func accountControlsFollowTheAuthenticatedSession() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "presentation", name: "Presentation")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .authSessions(services.sessions, store: services.authentication),
      site.pageServices,
    ],
    transportCapabilities: .persistent
  )

  for signedIn in [false, true] {
    let headers: HTTPFields = signedIn ? [.cookie: "robin-session=\(token.value)"] : [:]
    let overview = await responder.respond(
      to: Request(
        .init(method: .get, scheme: nil, authority: nil, path: "/en", headerFields: headers)
      )
    )
    #expect(overview.head.status == .ok)
    let overviewHTML = String(decoding: overview.body.bufferedBytes ?? [], as: UTF8.self)
    #expect(!overviewHTML.contains("id=\"login\""))
    #expect(!overviewHTML.contains("id=\"notes\""))
    #expect(overviewHTML.contains("Open notes"))
    #expect(overviewHTML.contains("href=\"/en/notes\""))
    #expect(overviewHTML.contains("href=\"/en/conversations\""))
    let response = await responder.respond(
      to: Request(
        .init(method: .get, scheme: nil, authority: nil, path: "/en/notes", headerFields: headers)
      )
    )
    #expect(response.head.status == .ok)
    let html = String(decoding: response.body.bufferedBytes ?? [], as: UTF8.self)
    #expect(html.contains("/api/v1/auth/logout") == signedIn)
    #expect(html.contains("id=\"register\"") == !signedIn)
    #expect(html.contains("id=\"login\"") == !signedIn)
    #expect(html.contains("id=\"content\"") == signedIn)
    #expect(html.contains("id=\"notes\"") == signedIn)
    #expect(html.contains("Sign in to manage your notes and join the conversation.") == !signedIn)
    #expect(html.contains("Secure sign-in with your device.") == !signedIn)
  }
  try await services.shutdown()
}
