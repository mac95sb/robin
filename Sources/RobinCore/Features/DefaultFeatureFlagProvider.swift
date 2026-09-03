/// A provider that uses flag defaults, useful for local development and deterministic tests.
public struct DefaultFeatureFlagProvider: FeatureFlagProvider {
  /// Creates a provider that always defers to flag defaults.
  public init() {}

  /// Returns no provider override.
  ///
  /// - Parameters:
  ///   - flag: The flag being evaluated.
  ///   - context: The evaluation context.
  /// - Returns: Always `nil`.
  public func value<Value: Equatable & Sendable>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value? { nil }
}
