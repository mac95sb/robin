import Foundation

/// Declares state with a Swift value used to initialize browser-local bindings.
///
/// Use the projected value (`$count`) in bindings and `#action { count += 1 }` for
/// browser mutations. Ordinary Swift reads and writes affect the next render's initial
/// value, not an already-loaded browser. Separate declarations have separate identities;
/// copies share storage. Never use browser state to store secrets or authorize server operations.
@propertyWrapper
public struct State<Value: StateValue>: Sendable {
  private let storage: Storage

  /// The Swift value used to initialize the next rendered document.
  /// Browser mutations do not write back to this property.
  public var wrappedValue: Value {
    get { storage.lock.withLock { storage.value } }
    nonmutating set {
      _ = stateJSON(newValue)
      storage.lock.withLock { storage.value = newValue }
    }
  }

  /// A typed browser reference capturing the current Swift value as its initial value.
  public var projectedValue: StateBinding<Value> {
    let value = wrappedValue
    return StateBinding(
      reference: StateReference(
        token: storage.token, kind: Value.stateKind, initial: stateJSON(value),
        localKey: storage.localKey),
      initialValue: value)
  }

  /// Declares state with an initial scalar value.
  /// - Parameter wrappedValue: A finite number, exact JavaScript integer, Boolean, or string.
  public init(wrappedValue: Value) {
    _ = stateJSON(wrappedValue)
    storage = Storage(value: wrappedValue, localKey: nil)
  }

  init(wrappedValue: Value, localKey: String?) {
    _ = stateJSON(wrappedValue)
    storage = Storage(value: wrappedValue, localKey: localKey)
  }

  // The lock protects the only mutable field; identity never changes.
  private final class Storage: @unchecked Sendable {
    let lock = NSLock()
    let token = UUID().uuidString
    let localKey: String?
    var value: Value
    init(value: Value, localKey: String?) {
      self.value = value
      self.localKey = localKey
    }
  }
}
