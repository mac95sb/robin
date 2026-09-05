import Crypto
import Foundation
import HTTPTypes
import RobinCore
import RobinJobs
import RobinPolar
import RobinServer
import Testing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Polar integration")
struct PolarIntegrationTests {
  @Test func rejectsInsecureRemoteAPI() throws {
    #expect(throws: PolarError.invalidConfiguration) {
      try PolarClient(
        accessToken: Secret("token"),
        environment: .custom(try #require(URL(string: "http://polar.example/v1"))))
    }
  }

  @Test func clientCreatesCheckoutWithoutGeneratedCode() async throws {
    let capture = RequestCapture()
    let client = try PolarClient(
      accessToken: Secret("token"),
      environment: .custom(try #require(URL(string: "https://polar.example/v1")))
    ) { request in
      await capture.record(request)
      return PolarHTTPResponse(
        statusCode: 201,
        body: Data(
          #"{"id":"checkout-1","status":"open","url":"https://checkout.example/1","subscription_id":"subscription-1"}"#
            .utf8))
    }

    let checkout = try await client.createCheckout(
      try PolarCheckoutRequest(
        products: ["product-1"], successURL: #require(URL(string: "https://example.com/paid"))))

    #expect(checkout.id == "checkout-1")
    #expect(checkout.subscriptionID == "subscription-1")
    #expect(await capture.request?.url?.path == "/v1/checkouts")
    #expect(await capture.request?.value(forHTTPHeaderField: "Authorization") == "Bearer token")
  }

  @Test func subscriptionDecodesProviderIdentifiers() async throws {
    let client = try PolarClient(accessToken: Secret("token")) { _ in
      PolarHTTPResponse(
        statusCode: 200,
        body: Data(
          #"{"id":"subscription-1","status":"active","product_id":"product-1","customer_id":"customer-1","cancel_at_period_end":false,"current_period_end":"2026-10-01T00:00:00Z"}"#
            .utf8))
    }
    let subscription = try await client.subscription(id: "subscription-1")
    #expect(subscription.productID == "product-1")
    #expect(subscription.customerID == "customer-1")
    #expect(!subscription.cancelAtPeriodEnd)
    #expect(subscription.currentPeriodEnd != nil)
  }

  @Test func webhookVerifiesBeforeDurableEnqueue() async throws {
    let queue = RecordingQueue()
    let now = Date(timeIntervalSince1970: 2_000)
    let secret = "webhook-secret"
    let body = Data(#"{"type":"subscription.updated"}"#.utf8)
    let message = Data("delivery-1.2000.".utf8) + body
    let signature = Data(
      HMAC<SHA256>.authenticationCode(
        for: message, using: SymmetricKey(data: Data(secret.utf8)))
    )
    .base64EncodedString()
    let route = try PolarWebhookRoute(
      secret: Secret(secret), jobs: JobClient(queue: queue), now: { now })
    let responder = try ApplicationResponder(
      routes: [route], transportCapabilities: .persistent)
    let request = Request(
      HTTPRequest(
        method: .post,
        scheme: "https",
        authority: "example.com",
        path: "/api/_robin/polar/webhook",
        headerFields: [
          HTTPField.Name("webhook-id")!: "delivery-1",
          HTTPField.Name("webhook-timestamp")!: "2000",
          HTTPField.Name("webhook-signature")!: "v1,\(signature)",
        ]),
      body: Array(body))

    #expect(await responder.respond(to: request).head.status == .accepted)
    let job = try #require(await queue.jobs.first)
    #expect(job.idempotencyKey == "none:robin.polar.webhook:delivery-1")
    #expect(
      try JSONDecoder().decode(PolarWebhookJob.self, from: job.payload).eventType
        == "subscription.updated")
  }
}

private actor RequestCapture {
  var request: URLRequest?
  func record(_ request: URLRequest) { self.request = request }
}

private actor RecordingQueue: JobQueue {
  var jobs: [QueuedJob] = []

  func enqueue(_ job: QueuedJob) -> String {
    jobs.append(job)
    return job.id
  }

  func claim(
    tenant _: TenantScope<String>, workerID _: String, now _: Date, leaseDuration _: TimeInterval
  ) -> JobClaim? { nil }
  func complete(_: JobClaim) {}
  func fail(_: JobClaim, message _: String, retryAt _: Date) -> JobFailureDisposition {
    .deadLettered
  }
  func deadLetters(tenant _: TenantScope<String>, limit _: Int) -> [QueuedJob] { [] }
  func shutdown() {}
}
