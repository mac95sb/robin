import Testing

@testable import RobinValidation

@Suite("Runtime actions")
struct ActionTests {
  @Test func actionPerformsAsynchronousOperation() async throws {
    let action = Action<Int, Int>(id: "increment") { amount in amount + 1 }

    #expect(try await action(2) == 3)
  }
}
