import Crypto
import Foundation
import HTTPTypes
import Testing

@testable import RobinServer

@Suite("Webhook verification middleware")
struct WebhookMiddlewareTests {
  @Test func acceptsOneFreshValidSignature() async throws {
    let secret = Data("secret".utf8)
    let timestamp = String(Int(Date().timeIntervalSince1970))
    let body = Data("payload".utf8)
    let signature = Data(
      HMAC<SHA256>.authenticationCode(
        for: Data(timestamp.utf8) + Data([46]) + body,
        using: SymmetricKey(data: secret)
      )
    ).map {
      let value = String($0, radix: 16)
      return value.count == 1 ? "0\(value)" : value
    }.joined()
    let middleware = Middleware.webhookSignature(
      secret: secret,
      replayProtector: ReplayProtector()
    )
    let responder = try ApplicationResponder(
      routes: [],
      middleware: [middleware],
      transportCapabilities: .persistent
    )
    let request = Request(
      HTTPRequest(
        method: .post,
        scheme: "https",
        authority: "example.com",
        path: "/webhook",
        headerFields: [
          HTTPField.Name("x-webhook-timestamp")!: timestamp,
          HTTPField.Name("x-webhook-signature")!: signature,
        ]
      ),
      body: Array(body)
    )

    #expect(await responder.respond(to: request).head.status == .notFound)
    #expect(await responder.respond(to: request).head.status == .unauthorized)
  }
}
