import RobinServer

/// An authenticated account and its authorization roles.
public struct AuthPrincipal: Equatable, Sendable {
  /// Stable account identifier.
  public let accountID: String
  /// Roles active for the account.
  public let roles: Set<Role>

  /// Creates a principal.
  public init(accountID: String, roles: Set<Role> = []) {
    precondition(!accountID.isEmpty)
    self.accountID = accountID
    self.roles = roles
  }

  /// Returns whether any role grants the permission.
  public func allows(_ permission: Permission) -> Bool {
    roles.contains { $0.permissions.contains(permission) }
  }

  /// The transport-neutral server principal projection.
  public var requestPrincipal: RequestContext.Principal {
    .init(id: accountID, roles: Set(roles.map(\.name)))
  }
}
