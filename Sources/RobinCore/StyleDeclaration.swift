/// An opaque style declaration carried by Render IR.
///
/// `StyleDeclaration` is the boundary type between Robin's structural render representation and
/// Robin's style system. RobinCore defines only its *shape*: a property key, a typed payload, and
/// a condition key. RobinCore deliberately defines none of the vocabulary — no CSS property
/// names, no token meanings, no condition semantics. `RobinHTML` lowering produces declarations;
/// `RobinStyle` interprets and compiles them into CSS.
///
/// Declarations are comparable only for identity. Meaningful interpretation (token resolution,
/// cascade ordering, CSS emission) belongs entirely to `RobinStyle`.
public struct StyleDeclaration: Hashable, Sendable {
  /// A declaration value whose interpretation is owned by the style system.
  public enum Payload: Hashable, Sendable {
    /// A canonical keyword chosen by lowering (for example, a layout behavior).
    case keyword(String)
    /// A reference to a design-system token resolved by the style system at compile time.
    case token(String)
    /// An integral value (for example, a pixel length or a numeric weight).
    case integer(Int)
  }

  /// The style-system property key the declaration applies to.
  public let property: String
  /// The declaration's value payload.
  public let payload: Payload
  /// The condition key under which the declaration applies. An empty string is unconditional.
  public let condition: String

  /// Creates a declaration at the render/style boundary.
  ///
  /// - Parameters:
  ///   - property: The style-system property key for this declaration.
  ///   - payload: The declaration's value payload.
  ///   - condition: The condition key under which the declaration applies. Defaults to
  ///     unconditional.
  @_spi(Rendering)
  public init(property: String, payload: Payload, condition: String = "") {
    self.property = property
    self.payload = payload
    self.condition = condition
  }
}
