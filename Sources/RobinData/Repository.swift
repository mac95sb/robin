import RobinCore

/// A request-scoped repository over plain application model values.
public protocol Repository: Sendable {
  /// A plain model that does not depend on Robin persistence APIs.
  associatedtype Model: Codable & Sendable

  /// Creates a repository for one request or job scope.
  init(context: RepositoryContext)
}

/// Database and tenant information shared by request-scoped repositories.
public struct RepositoryContext: Sendable {
  /// The application's database.
  public let database: any Database
  /// The verified tenant scope, or explicit absence of tenancy.
  public let tenant: TenantScope<String>

  /// Creates a repository context.
  public init(database: any Database, tenant: TenantScope<String> = .none) {
    self.database = database
    self.tenant = tenant
  }
}
