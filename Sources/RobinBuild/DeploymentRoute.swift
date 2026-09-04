/// A provider-neutral route from an incoming path to a deployment artifact.
public struct DeploymentRoute: Codable, Equatable, Sendable {
  /// The artifact selected by a route.
  public enum Destination: Codable, Equatable, Sendable {
    /// A static file artifact.
    case staticFile(String)
    /// An executable function artifact.
    case functionBundle(String)
    /// A WebAssembly function artifact.
    case webAssembly(String)
  }

  /// The absolute route pattern.
  public let pattern: String
  /// The selected artifact.
  public let destination: Destination
  /// Lower values take precedence when patterns overlap.
  public let precedence: Int

  /// Creates a deployment route.
  ///
  /// - Parameters:
  ///   - pattern: The absolute incoming route pattern.
  ///   - destination: The selected neutral artifact.
  ///   - precedence: The ordering rank; lower values match first.
  /// - Throws: ``BuildError/invalidDeploymentRoute(_:)`` for an unsafe pattern or destination.
  public init(pattern: String, destination: Destination, precedence: Int = 0) throws {
    guard pattern.hasPrefix("/"), !pattern.contains("\\"), !pattern.contains("..") else {
      throw BuildError.invalidDeploymentRoute(pattern)
    }
    let destinationPath =
      switch destination {
      case .staticFile(let path), .functionBundle(let path), .webAssembly(let path): path
      }
    guard BuildArtifact.isValid(destinationPath) else {
      throw BuildError.invalidDeploymentRoute(destinationPath)
    }
    self.pattern = pattern
    self.destination = destination
    self.precedence = precedence
  }
}
