import Foundation
import Testing

@testable import RobinCore

@Suite("Feature flags")
struct FeatureFlagTests {
  @Test func deterministicOverrideWinsOverProviderAndDefault() async throws {
    let flag = FeatureFlag("checkout", default: false)
    let flags = FeatureFlags(provider: DefaultFeatureFlagProvider(), overrides: ["checkout": true])
    let context = FeatureFlagContext(environment: "test")
    #expect(try await flags.value(for: flag, context: context))
  }

  @Test func expiredFlagsProduceRemovalDiagnostics() {
    let flag = FeatureFlag(
      "old", default: false, removalDate: .distantPast, fixedValueSince: .distantPast)
    let flags = FeatureFlags(provider: DefaultFeatureFlagProvider())
    #expect(flags.diagnostics(for: flag, now: .now).count == 2)
  }

  @Test func localRulesUseTheMostSpecificContextWithoutNetworkAccess() async throws {
    let flag = FeatureFlag("checkout", default: "control")
    let provider = LocalFeatureFlagProvider(rules: [
      LocalFeatureFlagRule("checkout", value: "environment", environment: "production"),
      LocalFeatureFlagRule(
        "checkout", value: "tenant", environment: "production", tenant: "acme"),
    ])
    let flags = FeatureFlags(provider: provider, overrides: ["checkout": "test"])
    #expect(
      try await flags.value(
        for: flag, context: .init(environment: "production", tenant: "acme")) == "test")
    let configured = FeatureFlags(provider: provider)
    #expect(
      try await configured.value(
        for: flag, context: .init(environment: "production", tenant: "acme")) == "tenant")
  }
}
