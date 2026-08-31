/// A component of a typed route pattern.
public enum RouteSegment: Equatable, Sendable {
  case literal(String)
  case parameter(String)
}
