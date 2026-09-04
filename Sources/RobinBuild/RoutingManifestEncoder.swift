/// Encodes neutral routes into a provider-consumable manifest artifact.
public protocol RoutingManifestEncoder: Sendable {
  /// Encodes routes ordered by precedence and pattern.
  ///
  /// - Parameter routes: Provider-neutral deployment routes.
  /// - Returns: A route-manifest artifact.
  /// - Throws: An encoder-specific error when routes cannot be represented.
  func encode(_ routes: [DeploymentRoute]) throws -> BuildArtifact
}
