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
