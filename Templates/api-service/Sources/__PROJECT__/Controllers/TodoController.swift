import Foundation
import RobinHTML
import RobinRouting
import RobinServer

struct TodoController: Controller {
  let todos: TodoService

  @RoutesBuilder var body: RouteList {
    ListTodos(todos: todos)
    ShowTodo(todos: todos)
    CreateTodo(todos: todos)
  }

  private struct ListTodos: Endpoint {
    let route = "todos"
    let todos: TodoService

    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> [Todo] {
      todos.all()
    }
  }

  private struct ShowTodo: Endpoint {
    let route = RouteDefinition.path(
      ["todos"],
      parameter: .integer("id"),
      metadata: .init(
        operationID: "todo.show",
        summary: "Returns one todo."))
    let todos: TodoService

    func handle(_ id: Int, request _: EmptyRequest, context _: RequestContext) throws -> Todo {
      guard let todo = todos.todo(id: id) else {
        throw ServerError(.notFound, "Todo not found.")
      }
      return todo
    }
  }

  private struct CreateTodo: Endpoint {
    let route = "todos"
    let method: HTTPMethod = .post
    let todos: TodoService

    func handle(
      _: Void,
      request: NewTodo,
      context _: RequestContext
    ) throws -> Todo {
      let title = request.title.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !title.isEmpty else { throw ServerError(.badRequest, "A title is required.") }
      guard let todo = todos.create(title: title) else {
        throw ServerError(.badRequest, "A title must be at most 200 UTF-8 bytes.")
      }
      return todo
    }
  }
}
