/// Two routes that resolve to the same structural path and method.
public struct RouteConflict: Error, Equatable, Sendable {
  /// The identifier registered first.
  public let first: String
  /// The conflicting identifier registered second.
  public let second: String
}

/// Detects structural route conflicts with a trie instead of pairwise comparisons.
public struct RouteConflictDetector {
  private final class Node {
    var literals: [String: Node] = [:]
    var parameter: Node?
    var owners: [String: String] = [:]
  }

  /// Validates that routes have distinct structural paths and methods.
  ///
  /// - Parameter routes: The resolved routes to inspect.
  /// - Throws: ``RouteConflict`` when two registrations overlap.
  public static func validate(_ routes: [RegisteredRoute]) throws {
    let root = Node()
    for route in routes {
      var node = root
      for segment in route.pattern.segments {
        switch segment {
        case .literal(let value):
          if node.literals[value] == nil { node.literals[value] = Node() }
          node = node.literals[value]!
        case .parameter:
          if node.parameter == nil { node.parameter = Node() }
          node = node.parameter!
        }
      }
      let key = route.method?.rawValue ?? "*"
      let conflict =
        node.owners["*"] ?? node.owners[key] ?? (key == "*" ? node.owners.values.first : nil)
      if let conflict { throw RouteConflict(first: conflict, second: route.identifier) }
      node.owners[key] = route.identifier
    }
  }
}
