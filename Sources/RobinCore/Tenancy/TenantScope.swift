/// Requires tenant-aware APIs to receive scope explicitly instead of consulting global state.
public enum TenantScope<ID: Hashable & Sendable>: Equatable, Sendable {
  /// An explicitly tenant-independent operation.
  case none
  /// An operation scoped to a verified tenant.
  case tenant(TenantContext<ID>)
}
