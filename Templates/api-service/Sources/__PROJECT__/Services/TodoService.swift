import Foundation

final class TodoService: @unchecked Sendable {
  static let maximumTitleBytes = 200
  static let maximumTodos = 1_000
  private let lock = NSLock()
  private var todos = [Todo(id: 1, title: "Ship Robin", completed: false)]

  func all() -> [Todo] { lock.withLock { todos } }

  func todo(id: Int) -> Todo? { lock.withLock { todos.first { $0.id == id } } }

  func create(title: String) -> Todo? {
    guard title.utf8.count <= Self.maximumTitleBytes else { return nil }
    return lock.withLock {
      let todo = Todo(id: (todos.last?.id ?? 0) + 1, title: title, completed: false)
      todos.append(todo)
      if todos.count > Self.maximumTodos { todos.removeFirst() }
      return todo
    }
  }
}
