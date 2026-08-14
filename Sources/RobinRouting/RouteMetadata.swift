/// Descriptive information shared with canonical URL and API tooling.
public struct RouteMetadata: Equatable, Sendable {
  /// A stable operation identifier for generated API descriptions.
  public let operationID: String?
  /// A concise, human-readable description of the route.
  public let summary: String?
  /// Whether tooling should treat generated absolute URLs as canonical.
  public let isCanonical: Bool

  /// Creates descriptive metadata for a route.
  ///
  /// - Parameters:
  ///   - operationID: An optional stable identifier for generated API descriptions.
  ///   - summary: An optional concise, human-readable description.
  ///   - isCanonical: Whether tooling should treat generated absolute URLs as canonical. The
  ///     default is `true`.
  public init(operationID: String? = nil, summary: String? = nil, isCanonical: Bool = true) {
    self.operationID = operationID
    self.summary = summary
    self.isCanonical = isCanonical
  }
}
