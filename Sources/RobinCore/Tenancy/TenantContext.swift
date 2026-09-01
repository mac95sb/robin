/// A verified tenant identity carried through request and service scopes.
public struct TenantContext<ID: Hashable & Sendable>: Equatable, Sendable {
  public enum Source: Equatable, Sendable {
    case hostname, route, authenticatedPrincipal
  }

  public let id: ID
  public let source: Source

  public init(verified id: ID, source: Source) {
    self.id = id
    self.source = source
  }
}

/// Requires tenant-aware APIs to receive scope explicitly instead of consulting global state.
public enum TenantScope<ID: Hashable & Sendable>: Equatable, Sendable {
  case none
  case tenant(TenantContext<ID>)
}
