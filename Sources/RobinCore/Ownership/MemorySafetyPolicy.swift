/// The declared memory-safety posture for a Robin target or dependency boundary.
public struct MemorySafetyPolicy: Equatable, Sendable {
  public struct UnsafeBoundary: Equatable, Sendable {
    public let name: String
    public let invariant: String

    public init(name: String, invariant: String) {
      self.name = name
      self.invariant = invariant
    }
  }

  public var strict: Bool
  public var auditedBoundaries: [UnsafeBoundary]

  public init(strict: Bool = true, auditedBoundaries: [UnsafeBoundary] = []) {
    self.strict = strict
    self.auditedBoundaries = auditedBoundaries
  }

  public var diagnostics: [Diagnostic] {
    auditedBoundaries.compactMap {
      $0.invariant.isEmpty
        ? Diagnostic(.error, "Unsafe boundary '\($0.name)' has no invariant") : nil
    }
  }
}
