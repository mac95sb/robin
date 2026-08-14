import Foundation
import Testing

@testable import RobinTooling

@Suite("Tool policy schema validation")
struct ToolPolicyTests {
  @Test func pklFixtureEvaluatesToVersionedTypedPolicy() throws {
    let input = try #require(
      Bundle.module.url(forResource: "robin", withExtension: "pkl", subdirectory: "Fixtures")
    )
    let process = Process()
    let output = Pipe()
    let errors = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["pkl", "eval", "-f", "json", input.path]
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()

    let errorOutput = String(
      decoding: errors.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )
    try #require(process.terminationStatus == 0, "pkl failed: \(errorOutput)")
    let policy = try JSONDecoder().decode(
      ToolPolicy.self,
      from: output.fileHandleForReading.readDataToEndOfFile()
    )
    try policy.validate()
    #expect(policy.schemaVersion == 1)
  }
}
