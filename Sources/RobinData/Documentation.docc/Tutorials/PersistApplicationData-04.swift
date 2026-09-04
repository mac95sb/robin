import RobinCore
import RobinData

struct User: Codable, Sendable {
  let id: Int64
  let name: String
}

enum UserRowError: Error {
  case invalid
}

let database = try await SQLiteDatabase(
  storage: .file(path: "/var/lib/my-app/app.sqlite"))
let repositoryContext = RepositoryContext(
  database: database,
  tenant: .tenant("acme"))

let users = DatabaseQuery<User>("SELECT id, name FROM users") { row in
  guard case .integer(let id) = row["id"],
    case .text(let name) = row["name"]
  else { throw UserRowError.invalid }
  return User(id: id, name: name)
}

let results = try await repositoryContext.database.withConnection { connection in
  try await connection.fetch(users)
}
