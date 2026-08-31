extension RouteDefinition {
  /// Appends another heterogeneous parameter to this route, allowing arbitrary typed composition.
  public func appending<Next: Sendable>(
    _ literals: [String] = [],
    parameter: PathParameter<Next>,
    suffix: [String] = []
  ) -> RouteDefinition<(Value, Next)> {
    let nextRoute = RouteDefinition<Next>.path(literals, parameter: parameter, suffix: suffix)
    let firstCount = pattern.segments.count
    let combinedPattern = RoutePattern(pattern.segments + nextRoute.pattern.segments)

    return RouteDefinition<(Value, Next)>(
      metadata: metadata,
      pattern: combinedPattern,
      match: { components in
        guard components.count == combinedPattern.segments.count else { return nil }
        let firstPath = "/" + components.prefix(firstCount).joined(separator: "/")
        let nextPath = "/" + components.dropFirst(firstCount).joined(separator: "/")
        guard let first = self.match(firstPath), let next = nextRoute.match(nextPath) else {
          return nil
        }
        return (first, next)
      },
      generate: { value in
        self.url(for: value.0).split(separator: "/").map(String.init)
          + nextRoute.url(for: value.1).split(separator: "/").map(String.init)
      }
    )
  }

  /// Creates a route with two heterogeneous typed path parameters.
  public static func path<First, Second>(
    _ prefix: [String] = [],
    first: PathParameter<First>,
    middle: [String] = [],
    second: PathParameter<Second>,
    suffix: [String] = [],
    metadata: RouteMetadata = .init()
  ) -> RouteDefinition<(First, Second)>
  where
    Value == (First, Second), First: Sendable,
    Second: Sendable
  {
    let firstRoute = RouteDefinition<First>.path(prefix, parameter: first, suffix: middle)
    let secondRoute = RouteDefinition<Second>.path([], parameter: second, suffix: suffix)
    let firstCount = firstRoute.pattern.segments.count
    let pattern = RoutePattern(firstRoute.pattern.segments + secondRoute.pattern.segments)

    return RouteDefinition<(First, Second)>(
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
