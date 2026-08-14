/// An HTML element in Robin's render IR: a tag, its attributes, and its children.
///
/// Element nodes are the building blocks of the render tree. Declare them with
/// the ``RenderBuilder`` DSL rather than assembling ``RenderNode`` values by hand:
///
/// ```swift
/// ElementNode(.article, attributes: [RenderAttribute("data-id", "1")]) {
///   ElementNode(.h2) { "Title" }
/// }
/// ```
public struct ElementNode: Equatable, Sendable {
  /// The HTML tag of the element.
  public let name: ElementName

  /// The element's attributes, in declaration order.
  ///
  /// Attribute order is not significant for rendering; ``HTMLRenderer`` sorts
  /// attributes name-and-value to keep emitted markup deterministic.
  public let attributes: [RenderAttribute]

  /// The element's children, in declaration order.
  public let children: [RenderNode]

  /// Creates an element node.
  ///
  /// - Parameters:
  ///   - name: The HTML tag of the element.
  ///   - attributes: The element's attributes. Defaults to none.
  ///   - children: A ``RenderBuilder`` closure declaring the element's children.
  ///     Defaults to an empty list.
  public init(
    _ name: ElementName,
    attributes: [RenderAttribute] = [],
    @RenderBuilder children: () -> [RenderNode] = { [] }
  ) {
    self.name = name
    self.attributes = attributes
    self.children = children()
  }
}
