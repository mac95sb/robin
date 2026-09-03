/// A provider-neutral feature-flag evaluation contract.
public protocol FeatureFlagProvider: Sendable {
  /// Evaluates a feature flag for one context.
  ///
  /// - Parameters:
  ///   - flag: The typed flag to evaluate.
  ///   - context: The server-side evaluation context.
  /// - Returns: A provider value, or `nil` to use the flag default.
  /// - Throws: A provider-specific evaluation error.
  func value<Value: Equatable & Sendable>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value?
}
