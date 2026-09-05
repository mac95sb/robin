import Logging
import NIOCore
import NIOSSL
import PostgresNIO
import RobinData

/// Connection settings for the official PostgreSQL adapter.
public struct PostgresConfiguration: Sendable {
  /// Transport security for the database connection.
  public enum TLS: Sendable {
    /// Connect without TLS, for local development only.
    case disable
    /// Use TLS when the server offers it.
    case prefer
    /// Require verified TLS.
    case require
  }

  /// PostgreSQL hostname.
  public var host: String
  /// PostgreSQL port.
  public var port: Int
  /// Authentication username.
  public var username: String
  /// Optional authentication password.
  public var password: String?
  /// Database name.
  public var database: String?
  /// Transport security policy.
  public var tls: TLS
  /// Maximum pooled connections.
  public var maximumConnections: Int

  /// Creates PostgreSQL connection settings.
  public init(
    host: String,
    port: Int = 5432,
    username: String,
    password: String? = nil,
    database: String? = nil,
    tls: TLS = .require,
    maximumConnections: Int = 20
  ) {
    precondition(port > 0 && port <= 65_535)
    precondition(maximumConnections > 0)
    self.host = host
    self.port = port
    self.username = username
    self.password = password
    self.database = database
    self.tls = tls
    self.maximumConnections = maximumConnections
  }
}
