import Foundation
import HTTPTypes
import RobinCore
import RobinHTML
import RobinRouting
import Testing

@testable import RobinServer

@Suite("Transport-neutral application responder")
struct ApplicationResponderTests {
  private struct Input: Codable, Sendable { let name: String }
  private struct Output: Codable, Sendable, Equatable {
    let id: Int
    let name: String
  }

  @Test func typedControllerMatchesDecodesAndEncodesWithoutNIO() async throws {
    let route = RouteDefinition<Int>.path(["users"], parameter: .integer("id"))
    let controller = Controller(route, method: .post, version: try Version(1)) {
      (id: Int, input: Input, _: RequestContext) in
      Output(id: id, name: input.name)
    }
    let responder = try ApplicationResponder(
      routes: [controller],
      transportCapabilities: .persistent
    )
    let request = Request(
      HTTPRequest(
        method: .post,
        scheme: "https",
        authority: "example.com",
        path: "/api/v1/users/7",
        headerFields: [.contentType: "application/json"]
      ),
      body: Array(#"{"name":"Robin"}"#.utf8)
    )

    let response = await responder.respond(
      to: request,
      context: RequestContext(requestID: "request-1")
    )

    #expect(response.head.status == .ok)
    #expect(
      try JSONDecoder().decode(Output.self, from: Data(try #require(response.body.bufferedBytes)))
        == Output(id: 7, name: "Robin"))
  }

  @Test func invalidJSONIsAClientErrorAndUnknownRoutesAreNotFound() async throws {
    let route = RouteDefinition<Void>.path("users")
    let controller = Controller(route, method: .post) {
      (_: Void, input: Input, _: RequestContext) in input
    }
    let responder = try ApplicationResponder(
      routes: [controller],
      transportCapabilities: .persistent
    )
    let invalid = Request(
      HTTPRequest(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/users",
        headerFields: [.contentType: "application/json"]
      ),
      body: Array("{".utf8)
    )
    let missing = Request(
      HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/missing")
    )

    #expect(await responder.respond(to: invalid).head.status == .badRequest)
    #expect(await responder.respond(to: missing).head.status == .notFound)
  }

  @Test func unsupportedTransportCapabilitiesFailAtStartup() {
    #expect(throws: TransportCapabilityError.self) {
      try ApplicationResponder(
        routes: [CapabilityRoute()],
        transportCapabilities: [.streaming]
      )
    }
  }

  private struct CapabilityRoute: ServerRoute {
    let metadata = RouteMetadata()
    let pattern = RoutePattern([])
    let requiredCapabilities: TransportCapabilities = [.webSockets, .persistentFileSystem]

    func respond(
      to request: Request,
      context: RequestContext,
      api: APIConfiguration
    ) async throws -> Response? { nil }
  }

  @Test func applicationPagesUseTheSameResponderAsControllers() async throws {
    struct Home: Page {
      let path = "/"
      var body: ComponentContent { Text { "Home" } }
    }
    struct TestApplication: App {
      var metadata: Metadata { Metadata() }
      var pages: some Pages { Home() }
    }
    let responder = try ApplicationResponder(
      TestApplication(),
      transportCapabilities: .persistent
    )

    let response = await responder.respond(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/"))
    )

    #expect(
      String(decoding: try #require(response.body.bufferedBytes), as: UTF8.self) == "<p>Home</p>"
    )
  }
}
