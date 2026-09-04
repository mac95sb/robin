import RobinServer
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func healthRouteRespondsSuccessfully() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/system/health")))
  #expect(response.head.status == .ok)
}

@Test func typedVersionedProjectRouteRespondsSuccessfully() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(
      .init(method: .get, scheme: nil, authority: nil, path: "/api/v1/catalog/projects/7")))
  #expect(response.head.status == .ok)
}

@Test func projectCreationAcceptsJSON() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(
      .init(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/api/v1/catalog/projects",
        headerFields: [.contentType: "application/json"]),
      body: Array(#"{"name":"New project"}"#.utf8)))
  #expect(response.head.status == .ok)
}
