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
}
