/// A named collection of authorization permissions.
public struct Role: Codable, Hashable, Sendable {
  /// The application-defined role name.
  public let name: String
  /// Permissions granted by the role.
  public let permissions: Set<Permission>

  /// Creates a role.
  public init(_ name: String, permissions: Set<Permission> = []) {
    precondition(!name.isEmpty)
    self.name = name
    self.permissions = permissions
  }
}
