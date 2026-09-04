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

  private struct UserEndpoint: Endpoint {
    let route = RouteDefinition.path(["users"], parameter: .integer("id"))
    let method: HTTPMethod = .post

    func handle(_ id: Int, request: Input, context _: RequestContext) -> Output {
      Output(id: id, name: request.name)
    }
  }

  private struct InvalidJSONEndpoint: Endpoint {
    let route = "users"
    let method: HTTPMethod = .post
    let version: Version? = nil

    func handle(_: Void, request: Input, context _: RequestContext) -> Input { request }
  }

  private struct HealthEndpoint: Endpoint {
    let route = "health"
    let version: Version? = nil

    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> EmptyRequest {
      EmptyRequest()
    }
  }

  private struct StatusController: Controller {
    @RoutesBuilder var body: RouteList { HealthEndpoint() }
  }

  @Test func endpointInfersContractsAndDefaultsToGET() {
    #expect(HealthEndpoint().method == .get)
    #expect(HealthEndpoint().pattern == RoutePattern([.literal("health")]))
  }

  @Test func controllerCollectsRelatedEndpoints() {
    #expect(StatusController().routes.count == 1)
  }

  @Test func typedControllerMatchesDecodesAndEncodesWithoutNIO() async throws {
    let controller = UserEndpoint()
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
    let controller = InvalidJSONEndpoint()
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

  @Test func nestedPageAndRouteGroupsComposeTheirPaths() async throws {
    struct Guide: Page {
      let path = "/"
      var body: ComponentContent { Text { "Guide" } }
    }
    struct TestApplication: App {
      var metadata: Metadata { Metadata() }

      @PagesBuilder var pages: PageList {
        PageGroup("docs") {
          PageGroup("guides") { Guide() }
        }
      }

      @RoutesBuilder var routes: RouteList {
        RouteGroup("system") {
          RouteGroup("status") { StatusController() }
        }
      }
    }
    let responder = try ApplicationResponder(
      TestApplication(),
      transportCapabilities: .persistent
    )

    let page = await responder.respond(
      to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/docs/guides"))
    )
    let route = await responder.respond(
      to: Request(
        HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/system/status/health")
      )
    )

    #expect(page.head.status == .ok)
    #expect(route.head.status == .ok)
  }
}
