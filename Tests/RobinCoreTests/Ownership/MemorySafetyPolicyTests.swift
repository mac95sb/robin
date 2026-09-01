import Testing

@testable import RobinCore

@Test func unsafeBoundariesRequireDocumentedInvariants() {
  let policy = MemorySafetyPolicy(auditedBoundaries: [.init(name: "C library", invariant: "")])
  #expect(policy.diagnostics.count == 1)
}
