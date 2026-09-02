import Foundation
import RobinRouting
import Testing

@Suite("Typed routes")
struct RouteTests {
  @Test func typedParameterMatchesAndReverseRoutes() {
    let route = RouteDefinition<Int>.path(
      ["users"],
      parameter: .integer("id"),
      metadata: .init(operationID: "showUser", summary: "Show a user")
    )

    #expect(route.match("/users/42?expanded=true#profile") == 42)
    #expect(route.match("/users/not-an-integer") == nil)
    #expect(route.url(for: 42) == "/users/42")
    #expect(
      route.canonicalURL(origin: URL(string: "https://example.com/")!, for: 42)?.absoluteString
        == "https://example.com/users/42")
    #expect(route.canonicalURL(origin: URL(string: "https://example.com/base")!, for: 42) == nil)
    #expect(route.metadata.operationID == "showUser")
  }

  @Test func stringParametersAreCanonicallyEncodedAndDecoded() {
    let route = RouteDefinition<String>.path(["articles"], parameter: .string("slug"))

    #expect(route.url(for: "hello world/Swift") == "/articles/hello%20world%2FSwift")
    #expect(route.match("/articles/hello%20world%2FSwift") == "hello world/Swift")
  }

  @Test func literalRoutesSupportRootAndStaticPaths() {
    let root = RouteDefinition<Void>.path()
    let docs = RouteDefinition<Void>.path("docs", "getting-started")

    #expect(root.match("/") != nil)
    #expect(root.url == "/")
    #expect(docs.match("/docs/getting-started") != nil)
    #expect(docs.url == "/docs/getting-started")
  }

  @Test func emptyRouteEdgeSegmentsAreCanonicalized() {
    let literal = RouteDefinition<Void>.path("", "docs", "")
    let typed = RouteDefinition<Int>.path(
      ["", "users"],
      parameter: .integer("id"),
      suffix: ["profile", ""]
    )

    #expect(literal.url == "/docs")
    #expect(literal.match(literal.url) != nil)
    #expect(typed.url(for: 42) == "/users/42/profile")
    #expect(typed.match(typed.url(for: 42)) == 42)
  }

  @Test func emptyInteriorSegmentsAreNotCollapsed() {
    let typed = RouteDefinition<Int>.path(["users"], parameter: .integer("id"))
    let literal = RouteDefinition<Void>.path("docs", "getting-started")

    #expect(typed.match("/users//42") == nil)
    #expect(literal.match("/docs//getting-started") == nil)
  }

  @Test func malformedPercentEscapesFailMatching() {
    let route = RouteDefinition<String>.path(["articles"], parameter: .string("slug"))

    #expect(route.match("/articles/incomplete%2") == nil)
    #expect(route.match("/articles/invalid%GG") == nil)
  }

  @Test func trailingSlashesRemainIgnoredWhenMatching() {
    let root = RouteDefinition<Void>.path()
    let typed = RouteDefinition<Int>.path(["users"], parameter: .integer("id"))
    let literal = RouteDefinition<Void>.path("docs", "getting-started")

    #expect(root.match("///") != nil)
    #expect(typed.match("/users/42/") == 42)
    #expect(literal.match("/docs/getting-started//") != nil)
  }
}
