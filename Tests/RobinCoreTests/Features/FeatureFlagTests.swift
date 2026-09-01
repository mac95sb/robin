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
    let flag = FeatureFlag("old", default: false, removalDate: .distantPast)
    let flags = FeatureFlags(provider: DefaultFeatureFlagProvider())
    #expect(flags.diagnostics(for: flag, now: .now).count == 1)
  }
}
