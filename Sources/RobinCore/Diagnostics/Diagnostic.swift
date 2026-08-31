/// A source-independent diagnostic emitted by Robin packages.
public struct Diagnostic: Equatable, Sendable {
  public enum Severity: Int, Comparable, Sendable {
    case note, warning, error

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
  }

  public let severity: Severity
  public let message: String
  public let context: String?

  public init(_ severity: Severity, _ message: String, context: String? = nil) {
    self.severity = severity
    self.message = message
    self.context = context
  }
}
