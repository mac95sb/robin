import RobinCore
import RobinRouting
import Testing

@testable import RobinServer

@Test func typedWebSocketRouteMatchesUpgradePathAndDeclaresCapabilities() async throws {
  let route = WebSocketRoute(requiredCapabilities: [.processLocalState]) { _ in
    WebSocketSession { _, _ in }
  }
  let request = Request(.init(method: .get, scheme: nil, authority: nil, path: "/api/v1"))
  let response = try await route.respond(
    to: request,
    context: RequestContext(requestID: "socket-route"),
    api: .default
  )

  #expect(route.requiredCapabilities == [.webSockets, .processLocalState])
  #expect(response?.body.isWebSocket == true)
}

extension ResponseBody {
  fileprivate var isWebSocket: Bool {
    if case .webSocket = self { return true }
    return false
  }
}
