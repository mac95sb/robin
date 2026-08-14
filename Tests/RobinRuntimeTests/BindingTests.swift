import Testing

@testable import RobinRuntime

@Suite("Runtime bindings")
struct BindingTests {
  @Test func bindingReadsAndWritesState() async throws {
    let store = StateStore()
    try await store.set(1, forKey: "count")
    let binding = Binding<Int>(
      id: "count",
      read: { try await store.value(forKey: "count", as: Int.self) ?? 0 },
      write: { try await store.set($0, forKey: "count") }
    )

    try await binding.set(3)

    #expect(try await binding.get() == 3)
  }
}
