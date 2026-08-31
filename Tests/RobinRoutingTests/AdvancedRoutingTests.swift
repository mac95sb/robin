import RobinRouting
import Testing

@Suite("Advanced routing")
struct AdvancedRoutingTests {
  private struct Request: Codable, Sendable {}
  private struct Response: Codable, Sendable {}

  @Test func heterogeneousParametersRoundTrip() {
    let route = TypedRoute<(String, Int)>.path(
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

  @Test func arbitraryHeterogeneousParametersComposeAndRoundTrip() {
    let route = TypedRoute<String>.path(
      ["organizations"], parameter: .string("organization"), suffix: ["repositories"]
    ).appending(parameter: .integer("repository"), suffix: ["releases"])
      .appending(parameter: .string("release"))

    let value = route.match("/organizations/robin/repositories/42/releases/v1")
    #expect(value?.0.0 == "robin")
    #expect(value?.0.1 == 42)
    #expect(value?.1 == "v1")
    #expect(
      route.url(for: (("robin", 42), "v1")) == "/organizations/robin/repositories/42/releases/v1")
  }

  @Test func structuralConflictsAreDiagnosed() {
    let a = RegisteredRoute("first", pattern: .init([.literal("users"), .parameter("id")]))
    let b = RegisteredRoute("second", pattern: .init([.literal("users"), .parameter("name")]))
    #expect(throws: RouteConflict.self) { try RouteConflictDetector.validate([a, b]) }
  }

  @Test func registryAllowsDifferentMethodsButRejectsDuplicateOperations() throws {
    let definition = TypedRoute<Void>.path("users")
    let get = APIEndpoint<Void, Request, Response>(definition, method: .get)
    let post = APIEndpoint<Void, Request, Response>(definition, method: .post)
    _ = try RouteRegistry([get, post])

    #expect(throws: RouteConflict.self) { try RouteRegistry([get, get]) }
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

  @Test func apiProtocolRegistryScopesVersionsAndContinuouslyGeneratesOpenAPI() throws {
    let definition = TypedRoute<Void>.path(
      "users", metadata: .init(operationID: "listUsers", summary: "List users"))
    let endpoint = APIEndpoint<Void, Request, Response>(
      definition, method: .get, version: try Version(2, status: .deprecated))
    let registry = try RouteRegistry([endpoint])
    let applicationRegistry = try RouteRegistry(applicationRoutes: [endpoint])

    func requireAPIRoute<R: APIRoute>(_: R) {}
    requireAPIRoute(endpoint)
    #expect(registry.routes.first?.pattern.openAPIPath == "/api/v2/users")
    #expect(applicationRegistry.routes == registry.routes)
    let first = try registry.openAPIDocument(title: "Robin", version: "1").generatedJSON()
    let second = try registry.openAPIDocument(title: "Robin", version: "1").generatedJSON()
    #expect(first == second)
    #expect(first.contains("\"/api/v2/users\""))
    #expect(first.contains("\"operationId\":\"listUsers\""))
    #expect(first.contains("\"deprecated\":true"))
  }

  @Test func typedRedirectsExecuteWithCanonicalLocationAndStatus() {
    let redirect = RouteRedirect(
      source: TypedRoute<String>.path(["posts"], parameter: .string("slug")),
      destination: TypedRoute<String>.path(["articles"], parameter: .string("slug")),
      isPermanent: false
    )

    #expect(
      redirect.response(for: "/posts/hello%20world")
        == RedirectResponse(statusCode: 307, location: "/articles/hello%20world"))
    #expect(redirect.response(for: "/other") == nil)
  }
}
