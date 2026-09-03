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

/// A route after application API scoping has been resolved.
public struct RegisteredRoute: Equatable, Sendable {
  /// The stable registration identifier.
  public let identifier: String
  /// The fully scoped route pattern.
  public let pattern: RoutePattern
  /// Descriptive route metadata.
  public let metadata: RouteMetadata
  /// The HTTP method for API routes.
  public let method: OpenAPIDocument.Method?
  /// The external version for API routes.
  public let version: Version?

  /// Creates a resolved route registration.
  ///
  /// - Parameters:
  ///   - identifier: The stable registration identifier.
  ///   - pattern: The fully scoped route pattern.
  ///   - metadata: Descriptive route metadata.
  ///   - method: The HTTP method for an API route.
  ///   - version: The external API version.
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
