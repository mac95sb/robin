import Foundation

/// Encodes deployment routes for Vercel Build Output API version 3.
public struct VercelRoutingManifestEncoder: RoutingManifestEncoder {
  /// Creates a Vercel route-manifest encoder.
  public init() {}

  /// Encodes routes after Vercel's filesystem check, preserving Robin precedence.
  ///
  /// - Parameter routes: Provider-neutral deployment routes.
  /// - Returns: `.vercel/output/config.json` as a deterministic artifact.
  /// - Throws: ``BuildError/invalidDeploymentRoute(_:)`` when a pattern or destination cannot be
  ///   represented by the Build Output API.
  public func encode(_ routes: [DeploymentRoute]) throws -> BuildArtifact {
    let ordered = routes.sorted { ($0.precedence, $0.pattern) < ($1.precedence, $1.pattern) }
    let encodedRoutes =
      try [Route(handle: "filesystem")]
      + ordered.map { route in
        Route(src: try source(for: route.pattern), dest: try destination(for: route.destination))
      }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try BuildArtifact(
      kind: .routeManifest,
      path: ".vercel/output/config.json",
      bytes: Array(try encoder.encode(Configuration(version: 3, routes: encodedRoutes))) + [10],
      dependencies: ordered.map(\.destination.path),
      mediaType: "application/json"
    )
  }

  private func source(for pattern: String) throws -> String {
    if pattern == "/" { return "^/$" }
    let wildcard = pattern.hasSuffix("/*")
    let path = wildcard ? String(pattern.dropLast(2)) : pattern
    guard !path.contains("*") else { throw BuildError.invalidDeploymentRoute(pattern) }
    let escaped = NSRegularExpression.escapedPattern(for: path)
      .replacingOccurrences(of: #"\/"#, with: "/")
    return wildcard ? "^\(escaped)(?:/.*)?$" : "^\(escaped)$"
  }

  private func destination(for destination: DeploymentRoute.Destination) throws -> String {
    switch destination {
    case .staticFile(let path):
      let prefix = ".vercel/output/static/"
      guard path.hasPrefix(prefix) else { throw BuildError.invalidDeploymentRoute(path) }
      return "/\(path.dropFirst(prefix.count))"
    case .functionBundle(let path), .webAssembly(let path):
      guard let function = path.split(separator: "/").first(where: { $0.hasSuffix(".func") })
      else { throw BuildError.invalidDeploymentRoute(path) }
      return "/\(function.dropLast(5))"
    }
  }
}

extension DeploymentRoute.Destination {
  fileprivate var path: String {
    switch self {
    case .staticFile(let path), .functionBundle(let path), .webAssembly(let path): path
    }
  }
}

extension VercelRoutingManifestEncoder {
  private struct Configuration: Encodable {
    let version: Int
    let routes: [Route]
  }

  private struct Route: Encodable {
    let src: String?
    let dest: String?
    let handle: String?

    init(src: String? = nil, dest: String? = nil, handle: String? = nil) {
      self.src = src
      self.dest = dest
      self.handle = handle
    }
  }
}
