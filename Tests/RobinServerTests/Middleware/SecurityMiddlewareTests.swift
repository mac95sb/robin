import HTTPTypes
import Testing

@testable import RobinServer

@Suite("Server security middleware")
struct SecurityMiddlewareTests {
  @Test func rejectsOversizedBodiesOriginsAndMissingCSRF() async throws {
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [.security(.init(allowedOrigins: ["https://example.com"], maximumBodyBytes: 2))],
      transportCapabilities: .persistent
    )

    #expect(
      await responder.respond(to: request(method: .get, body: [1, 2, 3])).head.status.code == 413)
    #expect(
      await responder.respond(
        to: request(method: .get, fields: [.origin: "https://attacker.example"])
      ).head.status == .forbidden
    )
    #expect(
      await responder.respond(
        to: request(
          method: .post,
          fields: [.contentType: "application/x-www-form-urlencoded"]
        )
      ).head.status == .forbidden
    )
  }

  @Test func acceptedRequestsReceiveBaselineSecurityHeaders() async throws {
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [.security(.init())],
      transportCapabilities: .persistent
    )
    let response = await responder.respond(to: request(method: .get))

    #expect(response.head.status == .notFound)
    #expect(response.head.headerFields[HTTPField.Name("x-content-type-options")!] == "nosniff")
    #expect(response.head.headerFields[HTTPField.Name("x-frame-options")!] == "DENY")
  }

  private func request(
    method: HTTPRequest.Method,
    fields: HTTPFields = [:],
    body: [UInt8] = []
  ) -> Request {
    Request(
      HTTPRequest(
        method: method,
        scheme: "https",
        authority: "example.com",
        path: "/",
        headerFields: fields
      ),
      body: body
    )
  }
}
