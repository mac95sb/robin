import Foundation

/// An actor-isolated, codable key-value state store.
public actor StateStore {
  private var values: [String: Data] = [:]

  public init() {}

  /// Encodes and stores a value for a key.
  public func set<Value: Codable & Sendable>(_ value: Value, forKey key: String) throws {
    values[key] = try JSONEncoder().encode(value)
  }

  /// Decodes the value stored for a key as the requested type.
  public func value<Value: Codable & Sendable>(forKey key: String, as: Value.Type) throws -> Value?
  {
    guard let data = values[key] else { return nil }
    return try JSONDecoder().decode(Value.self, from: data)
  }
}

/// An asynchronous, codable reference to runtime state.
public struct Binding<Value: Codable & Sendable>: Sendable {
  public let id: String
  private let read: @Sendable () async throws -> Value
  private let write: @Sendable (Value) async throws -> Void

  public init(
    id: String,
    read: @escaping @Sendable () async throws -> Value,
    write: @escaping @Sendable (Value) async throws -> Void
  ) {
    self.id = id
    self.read = read
    self.write = write
  }

  /// Reads the current value.
  public func get() async throws -> Value { try await read() }

  /// Replaces the current value.
  public func set(_ value: Value) async throws { try await write(value) }
}

/// A named asynchronous operation exposed to the runtime.
public struct Action<Input: Codable & Sendable, Output: Codable & Sendable>: Sendable {
  public let id: String
  private let operation: @Sendable (Input) async throws -> Output

  public init(id: String, operation: @escaping @Sendable (Input) async throws -> Output) {
    self.id = id
    self.operation = operation
  }

  /// Performs the action with an input value.
  public func callAsFunction(_ input: Input) async throws -> Output { try await operation(input) }
}

/// A string whose interpolation records references to runtime state.
public struct ReactiveString: ExpressibleByStringInterpolation, Sendable {
  /// A literal string or a reference to a state binding.
  public enum Segment: Equatable, Sendable {
    case literal(String)
    case state(String)
  }

  public struct StringInterpolation: StringInterpolationProtocol {
    fileprivate var segments: [Segment] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
      segments.reserveCapacity(interpolationCount * 2 + 1)
    }

    public mutating func appendLiteral(_ literal: String) {
      if !literal.isEmpty { segments.append(.literal(literal)) }
    }
    public mutating func appendInterpolation<Value>(_ binding: Binding<Value>) {
      segments.append(.state(binding.id))
    }
  }

  public let segments: [Segment]
  public init(stringLiteral value: String) { segments = [.literal(value)] }
  public init(stringInterpolation: StringInterpolation) { segments = stringInterpolation.segments }
}
