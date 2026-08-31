extension Route {
  /// Creates a route with two heterogeneous typed path parameters.
  public static func path<First, Second>(
    _ prefix: [String] = [],
    first: PathParameter<First>,
    middle: [String] = [],
    second: PathParameter<Second>,
    suffix: [String] = [],
    metadata: RouteMetadata = .init()
  ) -> Route<(First, Second)> where Value == (First, Second), First: Sendable, Second: Sendable {
    let firstRoute = Route<First>.path(prefix, parameter: first, suffix: middle)
    let secondRoute = Route<Second>.path([], parameter: second, suffix: suffix)
    let firstCount = firstRoute.pattern.segments.count
    let pattern = RoutePattern(firstRoute.pattern.segments + secondRoute.pattern.segments)

    return Route<(First, Second)>(
      metadata: metadata,
      pattern: pattern,
      match: { components in
        guard components.count == pattern.segments.count else { return nil }
        let firstPath = "/" + components.prefix(firstCount).joined(separator: "/")
        let secondPath = "/" + components.dropFirst(firstCount).joined(separator: "/")
        guard let a = firstRoute.match(firstPath), let b = secondRoute.match(secondPath) else {
          return nil
        }
        return (a, b)
      },
      generate: { value in
        let firstPath = firstRoute.url(for: value.0).split(separator: "/").map(String.init)
        let secondPath = secondRoute.url(for: value.1).split(separator: "/").map(String.init)
        return firstPath + secondPath
      }
    )
  }
}
