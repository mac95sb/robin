import Foundation

/// A typed, provider-neutral feature flag definition.
public struct FeatureFlag<Value: Equatable & Sendable>: Sendable {
  public let key: String
  public let defaultValue: Value
  public let removalDate: Date?

  public init(_ key: String, default defaultValue: Value, removalDate: Date? = nil) {
    self.key = key
    self.defaultValue = defaultValue
    self.removalDate = removalDate
  }
}

/// Context supplied to server-side feature-flag evaluation.
public struct FeatureFlagContext: Equatable, Sendable {
  public var environment: String
  public var user: String?
  public var cohort: String?
  public var tenant: String?

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
  func value<Value: Equatable & Sendable>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value?
}

/// Deterministic local values and test overrides with optional exposure reporting.
public struct FeatureFlags<Provider: FeatureFlagProvider>: Sendable {
  public typealias Exposure = @Sendable (String, FeatureFlagContext) -> Void

  private let provider: Provider
  private let overrides: [String: any Sendable]
  private let onExposure: Exposure?

  public init(
    provider: Provider,
    overrides: [String: any Sendable] = [:],
    onExposure: Exposure? = nil
  ) {
    self.provider = provider
    self.overrides = overrides
    self.onExposure = onExposure
  }

  public func value<Value>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value where Value: Equatable & Sendable {
    onExposure?(flag.key, context)
    if let override = overrides[flag.key] as? Value { return override }
    return try await provider.value(for: flag, context: context) ?? flag.defaultValue
  }

  public func diagnostics<Value>(for flag: FeatureFlag<Value>, now: Date) -> [Diagnostic] {
    guard let removalDate = flag.removalDate, removalDate <= now else { return [] }
    return [Diagnostic(.warning, "Feature flag '\(flag.key)' is past its removal date")]
  }
}

/// A provider that uses flag defaults, useful for local development and deterministic tests.
public struct DefaultFeatureFlagProvider: FeatureFlagProvider {
  public init() {}

  public func value<Value: Equatable & Sendable>(
    for flag: FeatureFlag<Value>,
    context: FeatureFlagContext
  ) async throws -> Value? { nil }
}
