import Foundation
import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func homePageHasNoStructuralAccessibilityFindings() {
  #expect(AccessibilityAudit.audit(DashboardPage(notes: NotesStore())).isEmpty)
}

@Test func notesCanBeCreatedUpdatedAndDeleted() async throws {
  let client = try RouteTestClient(Site())
  let contentType = "application/x-www-form-urlencoded"

  let created = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/notes",
        headerFields: [.contentType: contentType]),
      body: Array("content=Ship+Robin".utf8)))
  #expect(created.head.status == .seeOther)

  let updated = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/notes/2",
        headerFields: [.contentType: contentType]),
      body: Array("content=Ship+Robin+today".utf8)))
  #expect(updated.head.status == .seeOther)

  let listed = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1/notes")))
  #expect(
    String(bytes: listed.body.bufferedBytes ?? [], encoding: .utf8)?.contains("today") == true)

  let deleted = await client.response(
    to: Request(
      .init(method: .post, scheme: nil, authority: nil, path: "/api/v1/notes/2/delete")))
  #expect(deleted.head.status == .seeOther)

  let empty = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1/notes")))
  #expect(
    String(bytes: empty.body.bufferedBytes ?? [], encoding: .utf8)?.contains("today") == false)
}
