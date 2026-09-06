/// A deterministic single-node provider backed by application configuration.
public struct LocalFeatureFlagProvider: FeatureFlagProvider {
  private let rules: [LocalFeatureFlagRule]

  /// Creates a provider from ordered local rules.
  public init(rules: [LocalFeatureFlagRule]) { self.rules = rules }

  /// Resolves the most specific matching rule, using the first rule to break ties.
  ///
  /// Returns `nil` when no rule matches or the winning rule's value has a different type
  /// from the flag. This provider performs no network requests and does not throw.
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
