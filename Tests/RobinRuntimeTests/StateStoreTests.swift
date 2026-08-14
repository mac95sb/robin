import Testing

@testable import RobinRuntime

@Suite("Runtime state store")
struct StateStoreTests {
  @Test func valuesRoundTripThroughCodableStorage() async throws {
    let store = StateStore()
    try await store.set(1, forKey: "count")

    #expect(try await store.value(forKey: "count", as: Int.self) == 1)
  }
}
