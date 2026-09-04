/// A typed scroll or view timeline name.
public struct AnimationTimeline: Equatable, Hashable, Sendable {
  let cssName: String

  /// Creates a timeline from an ASCII identifier.
  ///
  /// - Parameter identifier: The unprefixed timeline identifier.
  /// - Throws: ``AdvancedStyleError/invalidIdentifier(_:)`` for an invalid CSS identifier.
  public init(_ identifier: String) throws {
    self.cssName = try cssCustomIdentifier(identifier)
  }
}
