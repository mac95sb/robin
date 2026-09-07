import Foundation
import RobinCore
import RobinRouting
import RobinServer

/// Serves the template's in-memory todo API.
///
/// The store is deliberately local to this controller. Replace it with durable storage when
/// todos must survive a process restart or be shared across instances.
actor TodoController: Controller {
  private static let maximumTitleBytes = 200
  /// Groups todo endpoints under `/api/v1/catalog`.
  let prefix = "catalog"
  private var todos: [Todo] = []

  /// Registers list, lookup, and creation endpoints for todos.
  nonisolated var body: RouteList {
    RouteGroup("todos") {
      GET { _, _ in await self.list() }
      GET(":id") { id, _ in try await self.show(id) }
      POST(Todo.self) { _, todo, _ in try await self.create(todo) }
    }
  }

  /// Returns every todo in creation order.
  func list() -> [Todo] { todos }

  /// Returns the todo identified by a route path value.
  ///
  /// - Parameter value: The UUID path value following `/todos/`.
  /// - Returns: The matching todo.
  /// - Throws: `ServerError` with a bad-request status for an invalid UUID or a not-found
  ///   status when no todo matches it.
  func show(_ value: String) throws -> Todo {
    guard let id = UUID(uuidString: value) else {
      throw ServerError(.badRequest, "Todo ID must be a UUID.")
    }
    guard let todo = todos.first(where: { $0.id == id }) else {
      throw ServerError(.notFound, "Todo not found.")
    }
    return todo
  }

  /// Validates and stores a new todo.
  ///
  /// - Parameter todo: The resource synthesized from the request's required create fields.
  /// - Returns: The stored todo with its server-generated values.
  /// - Throws: `ServerError` with a bad-request status when the title is blank or exceeds
  ///   200 UTF-8 bytes.
  func create(_ todo: Todo) throws -> Todo {
    let title = todo.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { throw ServerError(.badRequest, "A title is required.") }
    guard title.utf8.count <= Self.maximumTitleBytes else {
      throw ServerError(.badRequest, "A title must be at most 200 UTF-8 bytes.")
    }
    let todo = Todo(title: title)
    todos.append(todo)
    return todo
  }
}
