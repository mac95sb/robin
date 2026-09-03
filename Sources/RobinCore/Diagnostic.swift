/// A source-independent diagnostic emitted by Robin packages.
public struct Diagnostic: Equatable, Sendable {
  /// The importance of a diagnostic.
  public enum Severity: Int, Comparable, Sendable {
    /// Supplementary information that does not indicate a problem.
    case note
    /// A problem that permits work to continue.
    case warning
    /// A problem that prevents the requested work from completing.
    case error

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
  }

  /// The diagnostic's importance.
  public let severity: Severity
  /// A concise description of the problem.
  public let message: String
  /// Optional source or operation context for the problem.
  public let context: String?

  /// Creates a source-independent diagnostic.
  ///
  /// - Parameters:
  ///   - severity: The diagnostic's importance.
  ///   - message: A concise description of the problem.
  ///   - context: Optional source or operation context.
  public init(_ severity: Severity, _ message: String, context: String? = nil) {
    self.severity = severity
    self.message = message
    self.context = context
  }
}
