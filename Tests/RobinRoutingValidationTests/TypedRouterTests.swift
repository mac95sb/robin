import RobinRendering
import Testing

@testable import RobinRoutingValidation

@Suite("Typed route matching")
struct TypedRouterTests {
  @Test func routeMatchingDecodesParametersAndIgnoresQuery() {
    let router = TypedRouter(routes: [
      TypedRoute(method: .GET, segments: [.literal("users"), .parameter("id")]) { parameters in
        .element(ElementNode(.p) { "User \(parameters["id"] ?? "missing")" })
      }
    ])

    let match = router.match(method: .GET, path: "/users/a%20b?expanded=true")
    #expect(match.map(HTMLRenderer.render) == "<p>User a b</p>")
    #expect(router.match(method: .POST, path: "/users/a%20b") == nil)
    #expect(router.match(method: .GET, path: "/projects/a%20b") == nil)
  }
}
