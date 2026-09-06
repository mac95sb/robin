/// A context-targeted local feature-flag value.
public struct LocalFeatureFlagRule: Sendable {
  let key: String
  let environment: String?
  let user: String?
  let cohort: String?
  let tenant: String?
  let value: any Sendable

  /// Creates a local rule. Non-`nil` target fields must all match the evaluation context.
  public init<Value: Equatable & Sendable>(
    _ key: String,
    value: Value,
    environment: String? = nil,
    user: String? = nil,
    cohort: String? = nil,
    tenant: String? = nil
  ) {
    self.key = key
    self.environment = environment
    self.user = user
    self.cohort = cohort
    self.tenant = tenant
    self.value = value
  }

  func matches(_ context: FeatureFlagContext) -> Bool {
    (environment == nil || environment == context.environment)
      && (user == nil || user == context.user)
      && (cohort == nil || cohort == context.cohort)
      && (tenant == nil || tenant == context.tenant)
  }

  var specificity: Int {
    [environment, user, cohort, tenant].compactMap { $0 }.count
  }
}
