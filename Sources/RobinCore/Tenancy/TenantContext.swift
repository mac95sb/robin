/// A verified tenant identity carried through request and service scopes.
public struct TenantContext<ID: Hashable & Sendable>: Equatable, Sendable {
  /// The trusted source that established a tenant identity.
  public enum Source: Equatable, Sendable {
    /// The request hostname selected the tenant.
    case hostname
    /// A validated route value selected the tenant.
    case route
    /// An authenticated identity selected the tenant.
    case authenticatedPrincipal
  }

  /// The verified tenant identifier.
  public let id: ID
  /// The trusted source that established the identifier.
  public let source: Source

  /// Creates a verified tenant context.
  ///
  /// - Parameters:
  ///   - id: The verified tenant identifier.
  ///   - source: The trusted source that established the identifier.
  public init(verified id: ID, source: Source) {
    self.id = id
    self.source = source
  }
}
