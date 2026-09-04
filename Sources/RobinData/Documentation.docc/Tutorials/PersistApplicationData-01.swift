import RobinData

let database = try await SQLiteDatabase(
  storage: .file(path: "/var/lib/my-app/app.sqlite"))
