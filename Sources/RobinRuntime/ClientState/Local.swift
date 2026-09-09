import Foundation

/// Browser state persisted as one JSON value in local storage.
@propertyWrapper
public struct Local<Value: Codable & Sendable>: Sendable {
  private let storage: Storage

  /// The persisted value used to initialize the next rendered document.
  public var wrappedValue: Value {
    get { storage.lock.withLock { storage.value } }
    nonmutating set {
      _ = localJSON(newValue)
      storage.lock.withLock { storage.value = newValue }
    }
  }

  /// A browser binding to the complete persisted value.
  public var projectedValue: LocalBinding<Value> {
    let value = wrappedValue
    return LocalBinding(
      reference: StateReference(
        token: storage.token, kind: .json, initial: localJSON(value), localKey: storage.key),
      initialValue: value)
  }

  /// The browser binding exposed by an application-owned local value.
  public var binding: LocalBinding<Value> { projectedValue }

  /// Creates application-owned local state.
  /// - Parameters:
  ///   - key: The nonempty local-storage key.
  ///   - defaultValue: The value used when the browser has no stored value.
  public init(_ key: String, default defaultValue: Value) {
    self.init(wrappedValue: defaultValue, key)
  }

  /// Creates local state stored under a nonempty application-defined key.
  public init(wrappedValue: Value, _ key: String) {
    precondition(!key.isEmpty, "Local state requires a storage key.")
    _ = localJSON(wrappedValue)
    storage = Storage(value: wrappedValue, key: key)
  }

  private final class Storage: @unchecked Sendable {
    let lock = NSLock()
    let token = UUID().uuidString
    let key: String
    var value: Value

    init(value: Value, key: String) {
      self.value = value
      self.key = key
    }
  }
}

/// A typed binding to one complete JSON value in local storage.
public struct LocalBinding<Value: Codable & Sendable>: Sendable {
  /// Renderer-facing state metadata.
  @_spi(Rendering) public let reference: StateReference
  /// The server-rendered initial value.
  public let initialValue: Value

  /// Replaces and persists the complete value.
  public func set(_ value: Value) -> StateAction {
    StateAction(reference: reference, operation: .set, value: localJSON(value))
  }

  /// Restores and persists the initial value.
  public func reset() -> StateAction { set(initialValue) }
}
