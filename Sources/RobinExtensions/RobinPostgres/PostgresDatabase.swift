import Foundation
import Logging
import NIOCore
import NIOSSL
import PostgresNIO
import RobinData

/// The official pooled PostgreSQL implementation of Robin's database contracts.
public final class PostgresDatabase: Database, Sendable {
  /// PostgreSQL's SQL dialect.
  public let dialect = SQLDialect.postgres
  private let client: PostgresClient
  private let logger: Logger
  private let runTask: Task<Void, Never>

  /// Creates and starts a PostgreSQL connection pool.
  public init(
    configuration: PostgresConfiguration, logger: Logger = Logger(label: "robin.postgres")
  ) {
    var options = PostgresClient.Configuration.Options()
    options.maximumConnections = configuration.maximumConnections
    let clientConfiguration = PostgresClient.Configuration(
      host: configuration.host,
      port: configuration.port,
      username: configuration.username,
      password: configuration.password,
      database: configuration.database,
      tls: configuration.tls.postgresTLS
    )
    var configured = clientConfiguration
    configured.options = options
    let client = PostgresClient(configuration: configured, backgroundLogger: logger)
    self.client = client
    self.logger = logger
    self.runTask = Task { await client.run() }
  }

  /// Leases one pooled connection for an operation.
  public func withConnection<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result {
    try await client.withConnection { connection in
      try await operation(PostgresConnectionAdapter(connection: connection, logger: logger))
    }
  }

  /// Leases a pooled connection and runs an atomic transaction.
  public func transaction<Result: Sendable>(
    _ operation: @Sendable (any DatabaseConnection) async throws -> Result
  ) async throws -> Result {
    try await client.withTransaction(logger: logger) { connection in
      let result = try await operation(
        PostgresConnectionAdapter(connection: connection, logger: logger))
      try Task.checkCancellation()
      return result
    }
  }

  /// Checks whether the database can execute a trivial query.
  public func isHealthy() async -> Bool {
    do {
      let rows = try await client.query("SELECT 1", logger: logger)
      for try await _ in rows {}
      return true
    } catch {
      return false
    }
  }

  /// Stops the connection pool and releases its connections.
  public func shutdown() async throws {
    runTask.cancel()
    await runTask.value
  }
}

private struct PostgresConnectionAdapter: DatabaseConnection {
  let dialect = SQLDialect.postgres
  let connection: PostgresConnection
  let logger: Logger

  func query(_ statement: SQLStatement) async throws -> [DatabaseRow] {
    let rendered = statement.render(for: dialect)
    var bindings = PostgresBindings(capacity: rendered.bindings.count)
    for value in rendered.bindings { try bindings.append(value) }
    let sequence = try await connection.query(
      PostgresQuery(unsafeSQL: rendered.sql, binds: bindings), logger: logger)
    var rows: [DatabaseRow] = []
    for try await row in sequence {
      rows.append(
        DatabaseRow(
          Dictionary(
            try row.map { cell in
              (cell.columnName, try cell.databaseValue)
            },
            uniquingKeysWith: { first, _ in first }
          )))
    }
    return rows
  }
}

extension PostgresConfiguration.TLS {
  fileprivate var postgresTLS: PostgresClient.Configuration.TLS {
    switch self {
    case .disable: .disable
    case .prefer: .prefer(.makeClientConfiguration())
    case .require: .require(.makeClientConfiguration())
    }
  }
}

extension PostgresBindings {
  fileprivate mutating func append(_ value: DatabaseValue) throws {
    switch value {
    case .null: appendNull()
    case .integer(let value): append(value)
    case .real(let value): append(value)
    case .text(let value): append(value)
    case .blob(let value): append(ByteBuffer(bytes: value))
    case .boolean(let value): append(value)
    }
  }
}

extension PostgresCell {
  fileprivate var databaseValue: DatabaseValue {
    get throws {
      guard bytes != nil else { return .null }
      switch dataType {
      case .bool:
        return .boolean(try decode(Bool.self))
      case .int2, .int4, .int8:
        return .integer(try decode(Int64.self))
      case .float4, .float8, .numeric:
        return .real(try decode(Double.self))
      case .bytea:
        return .blob(Data(try decode(ByteBuffer.self).readableBytesView))
      default:
        return .text(try decode(String.self))
      }
    }
  }
}
