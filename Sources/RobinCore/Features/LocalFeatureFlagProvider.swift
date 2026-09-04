/// A context-targeted local feature-flag value.
public struct LocalFeatureFlagRule: Sendable {
  fileprivate let key: String
  fileprivate let environment: String?
  fileprivate let user: String?
  fileprivate let cohort: String?
  fileprivate let tenant: String?
  fileprivate let value: any Sendable

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

  fileprivate func matches(_ context: FeatureFlagContext) -> Bool {
    (environment == nil || environment == context.environment)
      && (user == nil || user == context.user)
      && (cohort == nil || cohort == context.cohort)
      && (tenant == nil || tenant == context.tenant)
  }

  fileprivate var specificity: Int {
    [environment, user, cohort, tenant].compactMap { $0 }.count
  }
}

/// A deterministic single-node provider backed by application configuration.
public struct LocalFeatureFlagProvider: FeatureFlagProvider {
  private let rules: [LocalFeatureFlagRule]

  /// Creates a provider from ordered local rules.
  public init(rules: [LocalFeatureFlagRule]) { self.rules = rules }

  /// Resolves the most specific matching typed rule.
  public func value<Value: Equatable & Sendable>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value? {
    rules.enumerated()
      .filter { $0.element.key == flag.key && $0.element.matches(context) }
      .max {
        ($0.element.specificity, -$0.offset) < ($1.element.specificity, -$1.offset)
      }?.element.value as? Value
  }
}
