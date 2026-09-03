/// Context supplied to server-side feature-flag evaluation.
public struct FeatureFlagContext: Equatable, Sendable {
  /// The deployment environment used for evaluation.
  public var environment: String
  /// An optional user identifier.
  public var user: String?
  /// An optional experiment cohort identifier.
  public var cohort: String?
  /// An optional tenant identifier.
  public var tenant: String?

  /// Creates feature-flag evaluation context.
  ///
  /// - Parameters:
  ///   - environment: The deployment environment.
  ///   - user: An optional user identifier.
  ///   - cohort: An optional experiment cohort identifier.
  ///   - tenant: An optional tenant identifier.
  public init(
    environment: String, user: String? = nil, cohort: String? = nil, tenant: String? = nil
  ) {
    self.environment = environment
    self.user = user
    self.cohort = cohort
    self.tenant = tenant
  }
}
