import RobinRouting

/// A route that can produce a transport-neutral server response.
public protocol ServerRoute: Route {
  /// Transport features this route requires to preserve its semantics.
  var requiredCapabilities: TransportCapabilities { get }

  /// Responds when the request matches this route.
  ///
  /// - Parameters:
  ///   - request: The normalized request.
  ///   - context: Values scoped to this request.
  ///   - api: The application's API path configuration.
  /// - Returns: A response when the route matches, or `nil` otherwise.
  /// - Throws: An error raised while decoding or handling the request.
  func respond(
    to request: RobinServer.Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response?
}

package func relativePath(
  _ path: String,
  api: APIConfiguration,
  version: Version?
) -> String? {
  let prefix = api.root.value + (version.map { "/v\($0.number)" } ?? "")
  guard path == prefix || path.hasPrefix(prefix + "/") else { return nil }
  let relative = path.dropFirst(prefix.count)
  return relative.isEmpty ? "/" : String(relative)
}

extension OpenAPIDocument.Method {
  package func matches(_ method: String) -> Bool {
    rawValue.caseInsensitiveCompare(method) == .orderedSame
  }
}
