import RobinCore
import RobinHTML
import RobinRouting
import RobinServer

struct ProjectsController: Controller {
  @RoutesBuilder var body: RouteList {
    ShowProject()
    DeleteProject()
  }

  private struct ShowProject: Endpoint {
    let route = RouteDefinition.path(["projects"], parameter: .integer("id"))

    func handle(_ id: Int, request _: EmptyRequest, context _: RequestContext) -> Project {
      Project(id: id)
    }
  }

  private struct DeleteProject: Endpoint {
    let route = RouteDefinition.path(["projects"], parameter: .integer("id"))
    let method = HTTPMethod.delete

    func handle(_ id: Int, request _: EmptyRequest, context _: RequestContext) -> Project {
      Project(id: id)
    }
  }
}

struct Project: Encodable, Sendable {
  let id: Int
}

@main
struct Site: App {
  @RoutesBuilder var routes: RouteList { ProjectsController() }

  static func main() async throws { try await RobinApplication.run(Self()) }
}
