import Foundation

/// Encodes provider-neutral deployment routes as deterministic JSON.
public struct JSONRoutingManifestEncoder: RoutingManifestEncoder {
  /// The relative manifest output path.
  public let path: String

  /// Creates a JSON route-manifest encoder.
  ///
  /// - Parameter path: The relative manifest output path.
  /// - Throws: ``BuildError/invalidArtifactPath(_:)`` for an unsafe path.
  public init(path: String = "routes.json") throws {
    guard BuildArtifact.isValid(path) else { throw BuildError.invalidArtifactPath(path) }
    self.path = path
  }

  /// Encodes routes ordered by precedence and pattern.
  ///
  /// - Parameter routes: Provider-neutral deployment routes.
  /// - Returns: A deterministic JSON route-manifest artifact.
  /// - Throws: An encoding or artifact-validation error.
  public func encode(_ routes: [DeploymentRoute]) throws -> BuildArtifact {
    let ordered = routes.sorted {
      ($0.precedence, $0.pattern) < ($1.precedence, $1.pattern)
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let dependencies = ordered.map { route in
      switch route.destination {
      case .staticFile(let path), .functionBundle(let path), .webAssembly(let path): path
      }
    }
    return try BuildArtifact(
      kind: .routeManifest,
      path: path,
      bytes: Array(try encoder.encode(ordered)),
      dependencies: dependencies,
      mediaType: "application/json"
    )
  }
}
