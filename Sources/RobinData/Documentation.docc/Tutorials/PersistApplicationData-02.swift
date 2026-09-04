import RobinData

let database = try await SQLiteDatabase(
  storage: .file(path: "/var/lib/my-app/app.sqlite"))

try await Migrator(database: database).migrate([
  Migration(
    version: 1,
    name: "Create users",
    statements: [
      "CREATE TABLE users (id BIGINT PRIMARY KEY, name TEXT NOT NULL)"
    ])
])
