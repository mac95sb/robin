import Testing

@testable import RobinValidation

@Suite("Runtime state, bindings and actions")
struct RuntimeStateTests {
  @Test func bindingAndActionCompleteServerRoundTrip() async throws {
    let store = StateStore()
    try await store.set(1, forKey: "count")
    let binding = Binding<Int>(
      id: "count",
      read: { try await store.value(forKey: "count", as: Int.self) ?? 0 },
      write: { try await store.set($0, forKey: "count") }
    )
    let increment = Action<Int, Int>(id: "increment") { amount in
      let value = try await binding.get() + amount
      try await binding.set(value)
      return value
    }
    let text: ReactiveString = "Count: \(binding)"

    #expect(text.segments == [.literal("Count: "), .state("count")])
    #expect(try await increment(2) == 3)
    #expect(try await binding.get() == 3)
  }
}
