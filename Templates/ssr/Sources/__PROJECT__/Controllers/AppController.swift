import Foundation
import RobinCore
import RobinHTML
import RobinRouting
import RobinServer

struct AppController: Controller {
  let notes: NotesStore

  @RoutesBuilder var body: RouteList {
    HealthEndpoint()
    ListNotes(notes: notes)
    NoteMutation(.create, notes: notes)
    NoteMutation(.update, notes: notes)
    NoteMutation(.delete, notes: notes)
  }

  private struct HealthEndpoint: Endpoint {
    let route = RouteDefinition.path("system", "health")
    let version: Version? = nil

    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> Health {
      Health(status: "ok")
    }
  }

  private struct ListNotes: Endpoint {
    let route = "notes"
    let notes: NotesStore

    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> [Note] {
      notes.all()
    }
  }

  private struct NoteMutation: APIRoute, ServerRoute {
    enum Operation { case create, update, delete }

    let operation: Operation
    let notes: NotesStore
    let method = HTTPMethod.post
    let version: Version? = .default
    let requiredCapabilities: TransportCapabilities = [.processLocalState]

    init(_ operation: Operation, notes: NotesStore) {
      self.operation = operation
      self.notes = notes
    }

    var metadata: RouteMetadata {
      .init(operationID: "notes.\(operation)", summary: "\(operation) a note.")
    }

    var pattern: RoutePattern {
      switch operation {
      case .create: RoutePattern([.literal("notes")])
      case .update: RoutePattern([.literal("notes"), .parameter("id")])
      case .delete: RoutePattern([.literal("notes"), .parameter("id"), .literal("delete")])
      }
    }

    func respond(
      to request: Request,
      context _: RequestContext,
      api: APIConfiguration
    ) -> Response? {
      guard request.method.rawValue.caseInsensitiveCompare(method.rawValue) == .orderedSame else {
        return nil
      }
      let prefix = Version.default.path(relativePath: "", api: api)
      guard request.path.hasPrefix(prefix + "/") else { return nil }
      let parts = request.path.dropFirst(prefix.count).split(separator: "/").map(String.init)

      switch operation {
      case .create:
        guard parts == ["notes"], let content = request.formValue(named: "content") else {
          return nil
        }
        notes.create(content)
      case .update:
        guard
          parts.count == 2,
          parts[0] == "notes",
          let id = Int(parts[1]),
          let content = request.formValue(named: "content")
        else {
          return nil
        }
        notes.update(id, content: content)
      case .delete:
        guard
          parts.count == 3,
          parts[0] == "notes",
          parts[2] == "delete",
          let id = Int(parts[1])
        else { return nil }
        notes.delete(id)
      }

      let returnPath = request.header(.referer).flatMap { URL(string: $0)?.path } ?? "/"
      return .redirect(to: returnPath)
    }
  }
}

private struct Health: Encodable, Sendable {
  let status: String
}
