import Foundation

/// Renderer-facing state metadata. Tokens are replaced by deterministic document-local identifiers.
public struct StateReference: Equatable, Sendable {
  /// Internal identity shared by a declaration's bindings and actions.
  public let token: String
  /// The scalar's expected type.
  public let kind: StateValueKind
  /// The JSON-encoded initial value.
  public let initial: String
  /// An optional local-storage key for persisted primitive state.
  public let localKey: String?

  /// Creates renderer-facing metadata for one primitive binding.
  public init(token: String, kind: StateValueKind, initial: String, localKey: String? = nil) {
    self.token = token
    self.kind = kind
    self.initial = initial
    self.localKey = localKey
  }
  /// Plain initial text for server-rendered bindings.
  public var text: String {
    (try? JSONDecoder().decode(String.self, from: Data(initial.utf8))) ?? initial
  }
}
