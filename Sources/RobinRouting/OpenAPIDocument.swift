/// A deterministic, transport-neutral typed OpenAPI model consumed by generators.
public struct OpenAPIDocument: Equatable, Sendable {
  public struct Operation: Equatable, Sendable {
    public let method: Method
    public let pattern: RoutePattern
    public let metadata: RouteMetadata

    public init(method: Method, pattern: RoutePattern, metadata: RouteMetadata) {
      self.method = method
      self.pattern = pattern
      self.metadata = metadata
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
}
