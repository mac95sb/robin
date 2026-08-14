import Foundation
import NIOHTTP1

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
