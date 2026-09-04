import RobinHTML
import RobinRouting
import RobinServer

struct ProjectController: Controller {
  @RoutesBuilder var body: RouteList {
    ShowProject()
    CreateProject()
  }

  private struct ShowProject: Endpoint {
    let route = RouteDefinition.path(
      ["projects"],
      parameter: .integer("id"),
      metadata: .init(
        operationID: "project.show",
        summary: "Returns one project from the catalog."))

    /// Returns a project by its stable identifier.
    ///
    /// Native clients can decode the response using the same `Project` model exported by Robin.
    func handle(_ id: Int, request _: EmptyRequest, context _: RequestContext) -> Project {
      Project(id: id, name: "Robin", status: "active")
    }
  }

  private struct CreateProject: Endpoint {
    let route = "projects"
    let method: HTTPMethod = .post

    /// Creates a project from a typed JSON request.
    func handle(
      _: Void,
      request: NewProject,
      context _: RequestContext
    ) -> Project {
      Project(id: 1, name: request.name, status: "active")
    }
  }
}

struct NewProject: Codable, Sendable {
  let name: String
}

struct Project: Codable, Sendable {
  let id: Int
  let name: String
  let status: String
}
