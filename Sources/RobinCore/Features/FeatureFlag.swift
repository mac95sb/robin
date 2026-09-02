import Foundation

/// A typed, provider-neutral feature flag definition.
public struct FeatureFlag<Value: Equatable & Sendable>: Sendable {
  /// The provider-facing flag identifier.
  public let key: String
  /// The value used when no provider or override supplies one.
  public let defaultValue: Value
  /// The date after which the flag should be removed.
  public let removalDate: Date?

  /// Creates a typed feature flag.
  ///
  /// - Parameters:
  ///   - key: The provider-facing identifier.
  ///   - defaultValue: The deterministic fallback value.
  ///   - removalDate: An optional deadline for removing the flag.
  public init(_ key: String, default defaultValue: Value, removalDate: Date? = nil) {
    self.key = key
    self.defaultValue = defaultValue
    self.removalDate = removalDate
  }
}

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

  /// Reports whether a flag is past its removal date.
  ///
  /// - Parameters:
  ///   - flag: The flag to inspect.
  ///   - now: The date used for the comparison.
  /// - Returns: A removal warning when the deadline has passed; otherwise, an empty array.
  public func diagnostics<Value>(for flag: FeatureFlag<Value>, now: Date) -> [Diagnostic] {
    guard let removalDate = flag.removalDate, removalDate <= now else { return [] }
    return [Diagnostic(.warning, "Feature flag '\(flag.key)' is past its removal date")]
  }
}

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
