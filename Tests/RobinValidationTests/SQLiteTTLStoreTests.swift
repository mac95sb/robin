import Testing

@testable import RobinValidation

@Suite("SQLite TTL store with namespaced, conditional and expiring writes")
struct SQLiteTTLStoreTests {
  @Test func sqliteTTLNamespacesCleanupAndConditionalRaceAreDeterministic() async throws {
    let store = try await SQLiteTTLStore()
    do {
      #expect(try await store.put("one", forKey: "a", inNamespace: "session", expiresAt: 20))
      #expect(try await store.put("two", forKey: "a", inNamespace: "passkey", expiresAt: 30))
      #expect(try await store.value(forKey: "a", inNamespace: "session", at: 19) == "one")
      #expect(try await store.value(forKey: "a", inNamespace: "session", at: 20) == nil)
      #expect(try await store.removeExpired(at: 20, limit: 1) == 1)
      #expect(try await store.value(forKey: "a", inNamespace: "passkey", at: 20) == "two")

      let winners = try await withThrowingTaskGroup(of: Bool.self) { group in
        for index in 0..<20 {
          group.addTask {
            try await store.put(
              "\(index)",
              forKey: "winner",
              inNamespace: "race",
              expiresAt: 100,
              onlyIfAbsent: true
            )
          }
        }
        var values: [Bool] = []
        for try await value in group { values.append(value) }
        return values
      }
      #expect(winners.filter(\.self).count == 1)
      try await store.close()
    } catch {
      try? await store.close()
      throw error
    }
  }
}
