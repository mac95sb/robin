import Foundation
import HTTPTypes
import RobinAuth
import RobinData
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test(arguments: [false, true])
func notesCanBeCreatedUpdatedAndDeleted(enhanced: Bool) async throws {
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
  if enhanced { formHeaders[.accept] = "application/json" }

  let created = await responder.respond(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/notes",
        headerFields: formHeaders),
      body: Array("content=Ship+Robin".utf8)))
  #expect(created.head.status == (enhanced ? .ok : .seeOther))
  if !enhanced { #expect(created.head.headerFields[.location] == "/en/notes") }

  let invalid = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/notes", headerFields: formHeaders
      ),
      body: Array("content=+++".utf8)))
  #expect(invalid.head.status == .badRequest)
  let invalidHTML = String(decoding: invalid.body.bufferedBytes ?? [], as: UTF8.self)
  #expect(invalidHTML.contains("aria-invalid=\"true\"") == !enhanced)
  #expect(invalidHTML.contains("Write a note."))
  #expect(invalidHTML.contains(">   </textarea>") == !enhanced)

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
  #expect(updated.head.status == (enhanced ? .ok : .seeOther))

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
        headerFields: formHeaders)))
  #expect(deleted.head.status == (enhanced ? .ok : .seeOther))

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
