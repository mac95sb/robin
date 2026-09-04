import RobinRouting

struct Request: Codable, Sendable {}
struct Response: Codable, Sendable { let id: Int }

let route = RouteDefinition.path(["users"], parameter: .integer("id"))
let endpoint = APIEndpoint<Int, Request, Response>(route, method: .get)
let registry = try RouteRegistry([endpoint])

let userID = route.match("/users/42")
let userURL = route.url(for: 42)
