import NIOHTTP1

/// A component of a typed route pattern.
public enum RouteSegment: Equatable, Sendable {
  case literal(String)
  case parameter(String)
}

/// An HTTP method and path pattern paired with a rendering handler.
public struct TypedRoute: Sendable {
  public let method: HTTPMethod
  public let segments: [RouteSegment]
  public let handler: @Sendable ([String: String]) -> RenderNode

  public init(
    method: HTTPMethod,
    segments: [RouteSegment],
    handler: @escaping @Sendable ([String: String]) -> RenderNode
  ) {
    self.method = method
    self.segments = segments
    self.handler = handler
  }
}

/// Matches HTTP requests against typed route definitions.
public struct TypedRouter: Sendable {
  private let routes: [TypedRoute]

  public init(routes: [TypedRoute]) {
    self.routes = routes
  }

  /// Returns the rendered node for the first route matching a method and URI.
  ///
  /// Query and fragment components do not participate in path matching.
  public func match(method: HTTPMethod, path: String) -> RenderNode? {
    let pathOnly = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)[0]
      .split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
    let components = pathOnly.split(separator: "/").map(String.init)
    for route in routes where route.method == method && route.segments.count == components.count {
      var parameters: [String: String] = [:]
      let matches = zip(route.segments, components).allSatisfy { segment, component in
        switch segment {
        case .literal(let value):
          return value == component
        case .parameter(let name):
          parameters[name] = component.removingPercentEncoding ?? component
          return true
        }
      }
      if matches { return route.handler(parameters) }
    }
    return nil
  }
}
