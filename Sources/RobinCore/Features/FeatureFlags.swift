import Foundation

/// Deterministic local values and test overrides with optional exposure reporting.
public struct FeatureFlags<Provider: FeatureFlagProvider>: Sendable {
  /// A callback invoked whenever a flag value is requested.
  public typealias Exposure = @Sendable (String, FeatureFlagContext) -> Void

  private let provider: Provider
  private let overrides: [String: any Sendable]
  private let onExposure: Exposure?

  /// Creates a feature-flag evaluator.
  ///
  /// - Parameters:
  ///   - provider: The external or local value provider.
  ///   - overrides: Deterministic values keyed by flag identifier.
  ///   - onExposure: An optional evaluation callback.
  public init(
    provider: Provider,
    overrides: [String: any Sendable] = [:],
    onExposure: Exposure? = nil
  ) {
    self.provider = provider
    self.overrides = overrides
    self.onExposure = onExposure
  }

  /// Resolves a feature-flag value.
  ///
  /// Overrides take precedence over the provider, followed by the flag's default.
  ///
  /// - Parameters:
  ///   - flag: The typed flag to evaluate.
  ///   - context: The server-side evaluation context.
  /// - Returns: The resolved flag value.
  /// - Throws: An error thrown by the provider.
  public func value<Value>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value where Value: Equatable & Sendable {
    onExposure?(flag.key, context)
    if let override = overrides[flag.key] as? Value { return override }
    return try await provider.value(for: flag, context: context) ?? flag.defaultValue
  }

  /// Reports whether a flag is fixed or past its removal date.
  ///
  /// - Parameters:
  ///   - flag: The flag to inspect.
  ///   - now: The date used for the comparison.
  /// - Returns: A removal warning when the deadline has passed; otherwise, an empty array.
  public func diagnostics<Value>(for flag: FeatureFlag<Value>, now: Date) -> [Diagnostic] {
    var diagnostics: [Diagnostic] = []
    if let removalDate = flag.removalDate, removalDate <= now {
      diagnostics.append(
        Diagnostic(.warning, "Feature flag '\(flag.key)' is past its removal date"))
    }
    if let fixedValueSince = flag.fixedValueSince, fixedValueSince <= now {
      diagnostics.append(
        Diagnostic(
          .warning, "Feature flag '\(flag.key)' is permanently fixed and should be removed"))
    }
    return diagnostics
  }
}
