import RobinRouting
import Testing

@Suite("Advanced routing")
struct AdvancedRoutingTests {
  @Test func heterogeneousParametersRoundTrip() {
    let route = Route<(String, Int)>.path(
      ["teams"], first: .string("team"), middle: ["members"], second: .integer("member")
    )
    #expect(route.match("/teams/acme/members/42")?.0 == "acme")
    #expect(route.match("/teams/acme/members/42")?.1 == 42)
    #expect(route.url(for: ("acme", 42)) == "/teams/acme/members/42")
  }

  @Test func queriesDecodeAndGenerateCanonically() {
    let page = QueryParameter<Int>.integer("page")
    #expect(page.value(in: "/articles?page=3") == 3)
    #expect(page.appending(4, to: "/articles?tag=swift") == "/articles?tag=swift&page=4")
  }

  @Test func structuralConflictsAreDiagnosed() {
    let a = RegisteredRoute("first", pattern: .init([.literal("users"), .parameter("id")]))
    let b = RegisteredRoute("second", pattern: .init([.literal("users"), .parameter("name")]))
    #expect(throws: RouteConflict.self) { try RouteConflictDetector.validate([a, b]) }
  }

  @Test func apiRootsAndVersionsAreNormalized() throws {
    let api = try APIConfiguration(root: "internal/api/")
    #expect(try Version(2).path(relativePath: "/users", api: api) == "/internal/api/v2/users")
    #expect(throws: APIConfigurationError.self) { try Version(0) }
  }

  @Test func openAPIOperationsHaveStableOrdering() {
    let document = OpenAPIDocument(
      title: "Robin", version: "1",
      operations: [
        .init(method: .post, pattern: .init([.literal("users")]), metadata: .init()),
        .init(method: .get, pattern: .init([.literal("users")]), metadata: .init()),
      ])
    #expect(document.operations.map(\.method) == [.get, .post])
  }
}
