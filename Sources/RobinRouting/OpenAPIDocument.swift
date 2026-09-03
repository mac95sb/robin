import Foundation

/// A deterministic, transport-neutral typed OpenAPI model consumed by generators.
public struct OpenAPIDocument: Equatable, Sendable {
  /// One HTTP operation included in an OpenAPI document.
  public struct Operation: Equatable, Sendable {
    /// The operation's HTTP method.
    public let method: Method
    /// The operation's fully scoped path pattern.
    public let pattern: RoutePattern
    /// Descriptive operation metadata.
    public let metadata: RouteMetadata
    /// The optional external API version.
    public let version: Version?

    /// Creates an OpenAPI operation.
    ///
    /// - Parameters:
    ///   - method: The operation's HTTP method.
    ///   - pattern: The fully scoped path pattern.
    ///   - metadata: Descriptive operation metadata.
    ///   - version: An optional external API version.
    public init(
      method: Method,
      pattern: RoutePattern,
      metadata: RouteMetadata,
      version: Version? = nil
    ) {
      self.method = method
      self.pattern = pattern
      self.metadata = metadata
      self.version = version
    }
  }

  /// An HTTP method supported by Robin API routes.
  public enum Method: String, Equatable, Sendable {
    /// Retrieves a representation.
    case get
    /// Creates or submits a representation.
    case post
    /// Replaces a representation.
    case put
    /// Partially updates a representation.
    case patch
    /// Deletes a representation.
    case delete
  }
  /// The API title shown by documentation tools.
  public let title: String
  /// The application API document version.
  public let version: String
  /// Operations sorted deterministically by path and method.
  public let operations: [Operation]

  /// Creates a deterministically ordered OpenAPI document.
  ///
  /// - Parameters:
  ///   - title: The API title.
  ///   - version: The application API document version.
  ///   - operations: The operations to include.
  public init(title: String, version: String, operations: [Operation]) {
    self.title = title
    self.version = version
    self.operations = operations.sorted {
      ($0.pattern.openAPIPath, $0.method.rawValue) < ($1.pattern.openAPIPath, $1.method.rawValue)
    }
  }

  /// Serializes this model as byte-stable OpenAPI 3.1 JSON for generator input.
  public func generatedJSON() throws -> String {
    var paths: [String: [String: Any]] = [:]
    for operation in operations {
      var value: [String: Any] = ["responses": ["200": ["description": "Success"]]]
      if let operationID = operation.metadata.operationID { value["operationId"] = operationID }
      if let summary = operation.metadata.summary { value["summary"] = summary }
      if case .deprecated? = operation.version?.status { value["deprecated"] = true }
      paths[operation.pattern.openAPIPath, default: [:]][operation.method.rawValue] = value
    }
    let document: [String: Any] = [
      "openapi": "3.1.0",
      "info": ["title": title, "version": version],
      "paths": paths,
    ]
    let data = try JSONSerialization.data(
      withJSONObject: document,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    return String(decoding: data, as: UTF8.self)
  }
}
