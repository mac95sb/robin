import Foundation
import HTTPTypes
import RobinCore
import RobinHTML
import RobinRouting
import Testing

@testable import RobinServer

@Suite("Invocation runtimes")
struct InvocationRuntimeTests {
  private struct Echo: Codable, Equatable, Sendable { let value: String }

  private struct EchoEndpoint: Endpoint {
    let route = "echo"
    let method: HTTPMethod = .post
    let version: Version? = nil

    func handle(_: Void, request: Echo, context _: RequestContext) -> Echo { request }
  }

  private struct TestApplication: App {
    var metadata: Metadata { Metadata() }

    @RoutesBuilder var routes: RouteList { EchoEndpoint() }
  }

  @Test func persistentLambdaAndWASIProduceEquivalentHTTPResponses() async throws {
    let codec = AWSLambdaHTTPEventCodec()
    let lambda = try InvocationRuntime(TestApplication(), codec: codec)
    let event = InvocationEvent(
      id: "lambda-1",
      payload: Array(
        #"{"version":"2.0","rawPath":"/api/echo","rawQueryString":"tag=a&tag=b","cookies":["session=abc"],"headers":{"content-type":"application/json","host":"example.com","x-forwarded-proto":"https"},"requestContext":{"requestId":"request-1","http":{"method":"POST","path":"/api/echo","sourceIp":"203.0.113.1"}},"body":"{\"value\":\"Robin\"}","isBase64Encoded":false}"#
          .utf8
      )
    )
    let decoded = try codec.decode(event.payload)
    #expect(decoded.request.query == "tag=a&tag=b")
    #expect(decoded.request.cookie(named: "session") == "abc")
    #expect(decoded.request.head.authority == "example.com")
    #expect(decoded.clientAddress == "203.0.113.1")
    let lambdaBytes = try await lambda.respond(to: event)
    let lambdaResponse = try JSONDecoder().decode(LambdaResponse.self, from: Data(lambdaBytes))

    let wasi = try WASIRuntime(TestApplication(), adapter: TestWASIAdapter())
    let wasiResponse = try await wasi.respond(to: decoded.request)
    let persistent = try ApplicationResponder(
      TestApplication(), transportCapabilities: .persistent)
    let persistentResponse = await persistent.respond(to: decoded.request)

    #expect(lambdaResponse.statusCode == wasiResponse.head.status.code)
    #expect(lambdaResponse.statusCode == persistentResponse.head.status.code)
    #expect(Array(lambdaResponse.body.utf8) == wasiResponse.body.bufferedBytes)
    #expect(Array(lambdaResponse.body.utf8) == persistentResponse.body.bufferedBytes)
    #expect(lambdaResponse.isBase64Encoded == false)

    let missingEvent = InvocationEvent(
      id: "missing",
      payload: Array(
        #"{"version":"2.0","rawPath":"/missing","requestContext":{"http":{"method":"GET"}}}"#
          .utf8))
    let missing = try codec.decode(missingEvent.payload)
    let lambdaMissing = try JSONDecoder().decode(
      LambdaResponse.self,
      from: Data(try await lambda.respond(to: missingEvent)))
    let wasiMissing = try await wasi.respond(to: missing.request)
    let persistentMissing = await persistent.respond(to: missing.request)
    #expect(lambdaMissing.statusCode == 404)
    #expect(lambdaMissing.statusCode == wasiMissing.head.status.code)
    #expect(lambdaMissing.statusCode == persistentMissing.head.status.code)
  }

  @Test func awsCodecPreservesV1RepeatedFieldsAndBinaryBodies() throws {
    let codec = AWSLambdaHTTPEventCodec(payloadVersion: .v1)
    let invocation = try codec.decode(
      Array(
        #"{"path":"/files","httpMethod":"POST","headers":{"content-type":"application/octet-stream"},"multiValueHeaders":{"x-tag":["a","b"]},"multiValueQueryStringParameters":{"tag":["a","b"]},"body":"AAEC","isBase64Encoded":true,"requestContext":{"requestId":"request-2","identity":{"sourceIp":"203.0.113.2"}}}"#
          .utf8
      ))

    #expect(invocation.request.path == "/files")
    #expect(invocation.request.query == "tag=a&tag=b")
    #expect(invocation.request.body == [0, 1, 2])
    #expect(invocation.requestID == "request-2")
    #expect(invocation.clientAddress == "203.0.113.2")

    var fields = HTTPFields()
    fields.append(HTTPField(name: HTTPField.Name("x-tag")!, value: "a"))
    fields.append(HTTPField(name: HTTPField.Name("x-tag")!, value: "b"))
    fields.append(HTTPField(name: .setCookie, value: "session=abc; Secure"))
    let encoded = try codec.encode(Response(headers: fields, body: [0, 1, 2]))
    let response = try JSONDecoder().decode(LambdaResponse.self, from: Data(encoded))
    #expect(response.body == "AAEC")
    #expect(response.isBase64Encoded)
    #expect(response.multiValueHeaders?["x-tag"] == ["a", "b"])
    #expect(response.multiValueHeaders?["set-cookie"] == ["session=abc; Secure"])
  }

  @Test func invocationDeadlineCancelsApplicationWork() async throws {
    let runtime = try InvocationRuntime(SlowApplication(), codec: AWSLambdaHTTPEventCodec())
    let response = try await runtime.respond(
      to: InvocationEvent(
        id: "deadline",
        payload: Array(
          #"{"version":"2.0","rawPath":"/api/slow","requestContext":{"http":{"method":"GET"}}}"#
            .utf8
        ),
        deadline: ContinuousClock.now
      ))

    #expect(try JSONDecoder().decode(LambdaResponse.self, from: Data(response)).statusCode == 504)
  }

  @Test func codecsRejectUnbufferedBodiesAndInvalidRuntimeEndpoints() throws {
    let stream = AsyncThrowingStream<[UInt8], any Error> { $0.finish() }
    #expect(throws: InvocationCodecError.unsupportedResponseBody) {
      try AWSLambdaHTTPEventCodec().encode(Response(body: .stream(stream)))
    }
    #expect(throws: AWSLambdaRuntimeAPIError.missingEndpoint) {
      try AWSLambdaRuntimeAPIChannel(endpoint: URL(string: "file:///tmp/runtime")!)
    }
  }

  @Test func lifecycleReportsBadEventsAndContinues() async throws {
    let runtime = try InvocationRuntime(TestApplication(), codec: AWSLambdaHTTPEventCodec())
    let channel = TestChannel(events: [
      InvocationEvent(id: "bad", payload: Array("{}".utf8)),
      InvocationEvent(
        id: "good",
        payload: Array(
          #"{"version":"2.0","rawPath":"/api/echo","requestContext":{"http":{"method":"POST"}},"headers":{"content-type":"application/json"},"body":"{\"value\":\"ok\"}"}"#
            .utf8
        )
      ),
    ])

    try await runtime.run(using: channel)

    #expect(await channel.responseIDs() == ["good"])
    #expect(await channel.failureIDs() == ["bad"])
  }

  @Test func invocationRuntimesRejectPersistentCapabilities() {
    #expect(throws: TransportCapabilityError.self) {
      try InvocationRuntime(
        CapabilityApplication(),
        codec: AWSLambdaHTTPEventCodec()
      )
    }
  }

  private struct CapabilityApplication: App {
    var metadata: Metadata { Metadata() }
    @RoutesBuilder var routes: RouteList { CapabilityRoute() }
  }

  private struct SlowApplication: App {
    var metadata: Metadata { Metadata() }
    @RoutesBuilder var routes: RouteList { SlowEndpoint() }
  }

  private struct SlowEndpoint: Endpoint {
    let route = "slow"
    let version: Version? = nil

    func handle(
      _: Void,
      request _: EmptyRequest,
      context _: RequestContext
    ) async throws -> EmptyRequest {
      try await Task.sleep(for: .seconds(10))
      return EmptyRequest()
    }
  }

  private struct CapabilityRoute: ServerRoute {
    let metadata = RouteMetadata()
    let pattern = RoutePattern([])
    let requiredCapabilities: TransportCapabilities = [.webSockets]

    func respond(
      to request: Request,
      context: RequestContext,
      api: APIConfiguration
    ) async throws -> Response? { nil }
  }
}

private struct TestWASIAdapter: WASIHostAdapter {
  func request(from incoming: Request) -> Request { incoming }
  func response(from outgoing: Response) -> Response { outgoing }
}

private struct LambdaResponse: Decodable {
  let statusCode: Int
  let body: String
  let isBase64Encoded: Bool
  let multiValueHeaders: [String: [String]]?
}

private actor TestChannel: InvocationChannel {
  private var events: [InvocationEvent]
  private var responses: [String] = []
  private var failures: [String] = []

  init(events: [InvocationEvent]) { self.events = events }

  func next() -> InvocationEvent? {
    guard !events.isEmpty else { return nil }
    return events.removeFirst()
  }

  func respond(to invocationID: String, with payload: [UInt8]) {
    responses.append(invocationID)
  }

  func fail(invocationID: String, with _: String) {
    failures.append(invocationID)
  }

  func responseIDs() -> [String] { responses }
  func failureIDs() -> [String] { failures }
}
