import Foundation
import HTTPTypes
import RobinAuth
import RobinData
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func homePageHasNoStructuralAccessibilityFindings() {
  #expect(AccessibilityAudit.audit(DashboardPage()).isEmpty)
}

@Test func notesCanBeCreatedUpdatedAndDeleted() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "demo", name: "Demo")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let site = Site(services: services)
  let responder = try ApplicationResponder(
    site,
    middleware: [
      .security(.init(allowedOrigins: Site.allowedOrigins)),
      .authSessions(services.sessions, store: services.authentication),
    ],
    transportCapabilities: .persistent)
  let contentType = "application/x-www-form-urlencoded"
  let authenticated: HTTPFields = [
    .cookie: "robin-session=\(token.value)", .origin: Site.origin.absoluteString,
  ]
  var formHeaders = authenticated
  formHeaders[.contentType] = contentType

  let created = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/notes",
        headerFields: formHeaders),
      body: Array("content=Ship+Robin".utf8)))
  #expect(created.head.status == .seeOther)

  let invalid = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/notes", headerFields: formHeaders
      ),
      body: Array("content=+++".utf8)))
  #expect(invalid.head.status == .badRequest)
  let invalidHTML = String(decoding: invalid.body.bufferedBytes ?? [], as: UTF8.self)
  #expect(invalidHTML.contains("aria-invalid=\"true\""))
  #expect(invalidHTML.contains("Write a note."))
  #expect(invalidHTML.contains("value=\"   \""))

  let malformed = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/notes", headerFields: formHeaders
      ),
      body: Array("content=one&content=two".utf8)))
  #expect(malformed.head.status == .badRequest)

  let updated = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/notes/2",
        headerFields: formHeaders),
      body: Array("content=Ship+Robin+today".utf8)))
  #expect(updated.head.status == .seeOther)

  let listed = await responder.respond(
    to: Request(
      .init(
        method: .get, scheme: nil, authority: nil, path: "/api/v1/notes",
        headerFields: authenticated)))
  #expect(
    String(bytes: listed.body.bufferedBytes ?? [], encoding: .utf8)?.contains("today") == true)

  let deleted = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/notes/2/delete",
        headerFields: authenticated)))
  #expect(deleted.head.status == .seeOther)

  let empty = await responder.respond(
    to: Request(
      .init(
        method: .get, scheme: nil, authority: nil, path: "/api/v1/notes",
        headerFields: authenticated)))
  #expect(
    String(bytes: empty.body.bufferedBytes ?? [], encoding: .utf8)?.contains("today") == false)

  let anonymous = await responder.respond(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1/notes")))
  #expect(anonymous.head.status == .unauthorized)
  try await services.shutdown()
}

@Test func notesSurviveDatabaseReopen() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
  defer { try? FileManager.default.removeItem(at: directory) }
  let storage = SQLiteDatabase.Storage.file(
    path: directory.appendingPathComponent("db.sqlite").path)

  let first = try await DashboardServices(storage: storage)
  try await NotesStore(first.storage).create("Persistent note", ownerID: "demo")
  try await first.shutdown()

  let second = try await DashboardServices(storage: storage)
  #expect(
    try await NotesStore(second.storage).all(ownerID: "demo").contains {
      $0.content == "Persistent note"
    })
  try await second.shutdown()
}

@Test func concurrentNotesAreNotLost() async throws {
  let services = try await DashboardServices()
  let notes = NotesStore(services.storage)
  try await withThrowingTaskGroup(of: Void.self) { group in
    for number in 0..<20 {
      group.addTask { try await notes.create("Note \(number)", ownerID: "demo") }
    }
    try await group.waitForAll()
  }
  #expect(try await notes.all(ownerID: "demo").count == 21)
  try await services.shutdown()
}

@Test func durableSessionAuthenticatesAccountRoute() async throws {
  let services = try await DashboardServices()
  let account = try Account(id: "demo", name: "Demo")
  try await services.authentication.save(account)
  let token = try await services.sessions.create(for: account.id)
  let responder = try ApplicationResponder(
    Site(services: services),
    middleware: [.authSessions(services.sessions, store: services.authentication)],
    transportCapabilities: .persistent)

  let anonymous = await responder.respond(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1/account")))
  #expect(anonymous.head.status == .unauthorized)

  let authenticated = await responder.respond(
    to: Request(
      .init(
        method: .get,
        scheme: nil,
        authority: nil,
        path: "/api/v1/account",
        headerFields: [.cookie: "robin-session=\(token.value)"])))
  #expect(authenticated.head.status == .ok)
  try await services.shutdown()
}
