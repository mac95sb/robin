import Foundation

/// A deterministic, transport-neutral typed OpenAPI model consumed by generators.
public struct OpenAPIDocument: Equatable, Sendable {
  public struct Operation: Equatable, Sendable {
    public let method: Method
    public let pattern: RoutePattern
    public let metadata: RouteMetadata
    public let version: Version?

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

  public enum Method: String, Equatable, Sendable { case get, post, put, patch, delete }
  public let title: String
  public let version: String
  public let operations: [Operation]

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
