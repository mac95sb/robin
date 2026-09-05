import RobinCore

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
