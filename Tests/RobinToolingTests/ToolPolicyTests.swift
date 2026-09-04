import Foundation
import Testing

@testable import RobinTooling

@Suite("Tool policy schema validation")
struct ToolPolicyTests {
  @Test func pklFixtureEvaluatesToVersionedTypedPolicy() throws {
    let input = try #require(
      Bundle.module.url(forResource: "robin", withExtension: "pkl", subdirectory: "Fixtures")
    )
    let root = input.deletingLastPathComponent()
    let policy = try #require(try ToolPolicyLoader.load(at: root))
    #expect(policy.schemaVersion == 1)
    #expect(policy.lintSeverity == .error)
  }

  @Test func buildBudgetIsEnforcedAtItsBoundary() {
    #expect(throws: Never.self) {
      try RobinCommandRunner.validateBuildDuration(milliseconds: 1_000, budget: 1_000)
    }
    #expect(
      throws: RobinCommandRunnerError.buildBudgetExceeded(
        actualMilliseconds: 1_001,
        budgetMilliseconds: 1_000
      )
    ) {
      try RobinCommandRunner.validateBuildDuration(milliseconds: 1_001, budget: 1_000)
    }
  }
}
