import Foundation

/// A scalar value that can be stored in browser-local state.
/// Robin supplies conformances for `Bool`, `Int`, `Double`, and `String`.
/// Custom conformances must encode a JSON scalar matching `stateKind`.
public protocol StateValue: Codable, Sendable {
  /// The scalar representation used by browser bindings.
  static var stateKind: StateValueKind { get }
}

extension Bool: StateValue {
  /// The Boolean state representation.
  public static var stateKind: StateValueKind { .boolean }
}
extension Int: StateValue {
  /// The exact-integer state representation.
  public static var stateKind: StateValueKind { .integer }
}
extension Double: StateValue {
  /// The finite-number state representation.
  public static var stateKind: StateValueKind { .number }
}
extension String: StateValue {
  /// The string state representation.
  public static var stateKind: StateValueKind { .string }
}

func stateJSON<Value: StateValue>(_ value: Value) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  guard let data = try? encoder.encode(value) else {
    preconditionFailure("State requires a JSON scalar.")
  }
  let decoder = JSONDecoder()
  let valid: Bool
  switch Value.stateKind {
  case .boolean: valid = (try? decoder.decode(Bool.self, from: data)) != nil
  case .string: valid = (try? decoder.decode(String.self, from: data)) != nil
  case .integer:
    valid =
      (try? decoder.decode(Int.self, from: data)).map {
        (-9_007_199_254_740_991...9_007_199_254_740_991).contains($0)
      } ?? false
  case .number: valid = (try? decoder.decode(Double.self, from: data))?.isFinite == true
  case .json: valid = true
  }
  precondition(valid, "State requires a scalar matching its kind and numeric range.")
  return String(decoding: data, as: UTF8.self)
}

func localJSON<Value: Codable & Sendable>(_ value: Value) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  guard let data = try? encoder.encode(value) else {
    preconditionFailure("Local state requires a JSON-encodable value.")
  }
  return String(decoding: data, as: UTF8.self)
}
