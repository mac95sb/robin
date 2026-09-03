/// The structural path shape shared by matching, reverse routing, conflict checks, and OpenAPI.
public struct RoutePattern: Equatable, Sendable {
  /// A literal or typed-parameter position in a route path.
  public enum Segment: Equatable, Sendable {
    /// A path segment that must match the supplied text exactly.
    case literal(String)
    /// A named path-parameter position.
    case parameter(String)
  }

  /// The ordered segments in the route path.
  public let segments: [Segment]
  /// Creates a structural route pattern.
  ///
  /// - Parameter segments: The route segments in path order.
  public init(_ segments: [Segment]) { self.segments = segments }

  /// The root-relative OpenAPI path template.
  public var openAPIPath: String {
    "/"
      + segments.map {
        switch $0 {
        case .literal(let value): value
        case .parameter(let name): "{\(name)}"
        }
      }.joined(separator: "/")
  }
}
