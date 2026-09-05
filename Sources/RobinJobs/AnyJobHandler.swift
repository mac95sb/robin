import Foundation
import RobinCore

/// A type-erased, retry-safe typed job handler.
public struct AnyJobHandler: Sendable {
  package let type: String
  package let execute: @Sendable (Data, JobContext) async throws -> Void

  /// Erases a typed job handler.
  public init<Value: Job>(
    _ type: Value.Type,
    handle: @escaping @Sendable (Value, JobContext) async throws -> Void
  ) {
    self.type = type.name
    self.execute = { data, context in
      try await handle(JSONDecoder().decode(Value.self, from: data), context)
    }
  }
}
