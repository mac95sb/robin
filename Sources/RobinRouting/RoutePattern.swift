/// The structural path shape shared by matching, reverse routing, conflict checks, and OpenAPI.
public struct RoutePattern: Equatable, Sendable {
  public enum Segment: Equatable, Sendable {
    case literal(String)
    case parameter(String)
  }

  public let segments: [Segment]
  public init(_ segments: [Segment]) { self.segments = segments }

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

public struct RegisteredRoute: Equatable, Sendable {
  public let identifier: String
  public let pattern: RoutePattern
  public let metadata: RouteMetadata
  public let method: OpenAPIDocument.Method?
  public let version: Version?

  public init(
    _ identifier: String,
    pattern: RoutePattern,
    metadata: RouteMetadata = .init(),
    method: OpenAPIDocument.Method? = nil,
    version: Version? = nil
  ) {
    self.identifier = identifier
    self.pattern = pattern
    self.metadata = metadata
    self.method = method
    self.version = version
  }
}

public struct RouteConflict: Error, Equatable, Sendable {
  public let first: String
  public let second: String
}

/// Detects structural route conflicts with a trie instead of pairwise comparisons.
public enum RouteConflictDetector {
  private final class Node {
    var literals: [String: Node] = [:]
    var parameter: Node?
    var owners: [String: String] = [:]
  }

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
