struct NewTodo: Codable, Sendable {
  let title: String
}

struct Todo: Codable, Sendable {
  let id: Int
  let title: String
  let completed: Bool
}
