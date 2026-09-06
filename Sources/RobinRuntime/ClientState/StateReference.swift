import Foundation

/// Renderer-facing state metadata. Tokens are replaced by deterministic document-local identifiers.
public struct StateReference: Equatable, Sendable {
  /// Internal identity shared by a declaration's bindings and actions.
  public let token: String
  /// The scalar's expected type.
  public let kind: StateValueKind
  /// The JSON-encoded initial value.
  public let initial: String
  /// Plain initial text for server-rendered bindings.
  public var text: String {
    (try? JSONDecoder().decode(String.self, from: Data(initial.utf8))) ?? initial
  }
}
