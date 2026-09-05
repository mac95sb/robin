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

  @Test func trustedOriginProtectsNativeFormSubmissionsWithoutJavaScript() async throws {
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [.security(.init(allowedOrigins: ["https://example.com"]))],
      transportCapabilities: .persistent
    )

    let trusted = await responder.respond(
      to: request(
        method: .post,
        fields: [
          .origin: "https://example.com",
          .contentType: "application/x-www-form-urlencoded",
          .cookie: "robin-session=session",
        ]
      ))
    #expect(trusted.head.status == .notFound)

    let missingOrigin = await responder.respond(
      to: request(
        method: .post,
        fields: [
          .contentType: "application/x-www-form-urlencoded",
          .cookie: "robin-session=session",
        ]
      ))
    #expect(missingOrigin.head.status == .forbidden)
  }

  @Test func rateLimiterBoundsAttackerControlledKeys() async {
    let limiter = RateLimiter(limit: 1, capacity: 2)
    _ = await limiter.decision(for: "client:/one")
    _ = await limiter.decision(for: "client:/two")
    #expect(!(await limiter.decision(for: "client:/three")).isAllowed)
    #expect(!(await limiter.decision(for: "client:/one")).isAllowed)
    #expect(!(await limiter.decision(for: "client:/two")).isAllowed)
    #expect(await limiter.trackedKeyCount == 2)
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
