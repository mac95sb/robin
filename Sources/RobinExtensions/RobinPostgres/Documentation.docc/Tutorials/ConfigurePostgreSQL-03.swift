import RobinCore
import RobinData
import RobinPostgres

let configuration = PostgresConfiguration(
  host: "db.example.com",
  username: "app",
  password: nil,
  tls: .require,
  maximumConnections: 20)

let database = PostgresDatabase(configuration: configuration)
let repositoryContext = RepositoryContext(
  database: database,
  tenant: .tenant("acme"))
