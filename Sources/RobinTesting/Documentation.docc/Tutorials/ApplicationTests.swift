import HTTPTypes
import RobinCore
import RobinHTML
import RobinServer
import RobinTesting
import Testing

private struct HomePage: Page {
  let path = "/"
  var body: ComponentContent { Main { Heading { "Home" } } }
}

private struct Site: App {
  var pages: some Pages { HomePage() }
}

@Test func homeResponds() async throws {
  let client = try RouteTestClient(Site())
  let response = await client.response(
    to: Request(HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/"))
  )
  #expect(response.head.status == .ok)
  #expect(AccessibilityAudit.audit(HomePage()).isEmpty)
}
