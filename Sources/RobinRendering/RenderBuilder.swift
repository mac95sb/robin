/// A result builder that assembles render trees from declarative element lists.
///
/// `RenderBuilder` is the syntactic foundation of Robin's view IR. It lets you
/// declare an element's children as a trailing closure of expressions instead of
/// constructing ``RenderNode`` arrays by hand:
///
/// ```swift
/// ElementNode(.div) {
///   ElementNode(.h1) { "Hello" }
///   if showDetail {
///     ElementNode(.p) { "Detail" }
///   }
/// }
/// ```
///
/// The builder supports literals (`String` becomes ``RenderNode/text(_:)``),
/// ``ElementNode`` and ``RenderNode`` expressions, `if`/`else` conditionals,
/// `if let` optionals, and `for` loops.
@resultBuilder
public enum RenderBuilder {
  /// Lifts an already-built ``RenderNode`` expression into the builder.
  ///
  /// - Parameter expression: A render node produced elsewhere.
  /// - Returns: A single-element component wrapping `expression`.
  public static func buildExpression(_ expression: RenderNode) -> [RenderNode] { [expression] }

  /// Lifts an ``ElementNode`` expression into the builder.
  ///
  /// - Parameter expression: An element declared in a view body.
  /// - Returns: A single-element component wrapping `expression` as ``RenderNode/element(_:)``.
  public static func buildExpression(_ expression: ElementNode) -> [RenderNode] {
    [.element(expression)]
  }

  /// Lifts a string literal into the builder as escaped text.
  ///
  /// - Parameter expression: The literal text to render.
  /// - Returns: A single-element component wrapping `expression` as ``RenderNode/text(_:)``.
  public static func buildExpression(_ expression: String) -> [RenderNode] { [.text(expression)] }

  /// Combines the statements of a builder closure into one component.
  ///
  /// - Parameter components: The components produced by each statement in the closure.
  /// - Returns: All components flattened into a single node list, in declaration order.
  public static func buildBlock(_ components: [RenderNode]...) -> [RenderNode] {
    components.flatMap(\.self)
  }

  /// Handles an `if` without an `else`, emitting nothing when the condition is false.
  ///
  /// - Parameter component: The nodes produced by the branch, or `nil` when it was skipped.
  /// - Returns: The branch nodes, or an empty list.
  public static func buildOptional(_ component: [RenderNode]?) -> [RenderNode] { component ?? [] }

  /// Handles the `if` branch of an `if`/`else` conditional.
  ///
  /// - Parameter component: The nodes produced when the condition holds.
  /// - Returns: The component unchanged.
  public static func buildEither(first component: [RenderNode]) -> [RenderNode] { component }

  /// Handles the `else` branch of an `if`/`else` conditional.
  ///
  /// - Parameter component: The nodes produced when the condition does not hold.
  /// - Returns: The component unchanged.
  public static func buildEither(second component: [RenderNode]) -> [RenderNode] { component }

  /// Combines the iterations of a `for` loop into one component.
  ///
  /// - Parameter components: One node list per loop iteration.
  /// - Returns: All iterations flattened into a single node list, in iteration order.
  public static func buildArray(_ components: [[RenderNode]]) -> [RenderNode] {
    components.flatMap(\.self)
  }
}
