import RobinPostgres

func databaseConfiguration(
  host: String,
  username: String,
  password: String?
) -> PostgresConfiguration {
  PostgresConfiguration(
    host: host,
    username: username,
    password: password,
    tls: .require,
    maximumConnections: 20)
}
