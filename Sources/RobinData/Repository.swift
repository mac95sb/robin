import RobinCore

/// A request-scoped repository over plain application model values.
public protocol Repository: Sendable {
  /// A plain model that does not depend on Robin persistence APIs.
  associatedtype Model: Codable & Sendable

  /// Creates a repository for one request or job scope.
  init(context: RepositoryContext)
}
