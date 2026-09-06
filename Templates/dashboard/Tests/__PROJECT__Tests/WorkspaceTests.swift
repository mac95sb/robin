import HTTPTypes
import RobinAuth
import RobinServer
import Testing

@testable import __PROJECT__

@Test func workspaceSharesSessionsAndConversationsButKeepsNotesPrivate() async throws {
  let services = try await DashboardServices()
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .authSessions(services.sessions, store: services.authentication), site.pageServices,
    ],
    transportCapabilities: .persistent)
  let notes = NotesStore(services.storage)
  try await notes.create("Private launch checklist", ownerID: "alice")
  _ = try await services.messages.append("Hello workspace", authorID: "alice")

  for name in ["alice", "bob"] {
    try await services.authentication.save(Account(id: name, name: name))
    try await services.usernames.set(name, for: name)
    let token = try await services.sessions.create(for: name)
    let headers: HTTPFields = [.cookie: "robin-session=\(token.value)"]
    for locale in ["en", "fr"] {
      for page in ["", "/notes", "/conversations"] {
        let conversations = page == "/conversations"
        let notesPage = page == "/notes"
        let path = "/\(locale)" + page
        let response = await responder.respond(
          to: Request(
            .init(method: .get, scheme: nil, authority: nil, path: path, headerFields: headers)))
        #expect(response.head.status == .ok)
        let html = String(decoding: response.body.bufferedBytes ?? [], as: UTF8.self)
        #expect(!html.contains("id=\"login\""))
        #expect(html.contains("Hello workspace") == conversations)
        #expect(html.contains("Private launch checklist") == (notesPage && name == "alice"))
        #expect(html.contains("id=\"chat-form\"") == conversations)
        #expect(html.contains("id=\"notes\"") == notesPage)
      }
    }
    let saved = await responder.respond(
      to: Request(
        .init(
          method: .post, scheme: nil, authority: nil, path: "/api/v1/username",
          headerFields: [
            .cookie: "robin-session=\(token.value)",
            .contentType: "application/x-www-form-urlencoded",
            .referer: "http://localhost/fr/conversations",
          ]), body: Array("username=\(name)".utf8)))
    #expect(saved.head.headerFields[.location] == "/fr/conversations")
  }
  try await services.shutdown()
}
