import RobinCore

/// Verified context supplied to a job handler.
public struct JobContext: Sendable {
  /// Persistent job identifier.
  public let id: String
  /// Current one-based attempt number.
  public let attempt: Int
  /// Tenant that owns the job.
  public let tenant: TenantScope<String>
  /// Typed services shared with request handling and tests.
  public let services: ConfigurationValues
}
