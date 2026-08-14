/// Resolved component content used by Robin's result-builder pipeline.
///
/// A component's body produces this value after ``ViewBuilder`` has flattened its expressions into
/// an ordered collection of render nodes.
public struct ComponentContent: Component, Sendable {
  /// The structural nodes produced by the component body, in source order.
  @_spi(Rendering)
  public let nodes: [RenderNode]

  /// Creates resolved component content from structural render nodes.
  ///
  /// - Parameter nodes: The render nodes to preserve in source order.
  @_spi(Rendering)
  public init(nodes: [RenderNode]) {
    self.nodes = nodes
  }

  /// Returns this already-resolved component content.
  public var body: ComponentContent { self }
}

@_spi(Rendering)
extension ComponentContent {
  /// Creates component content containing a single render node.
  ///
  /// - Parameter node: The node to wrap.
  /// - Returns: Component content containing only the supplied node.
  public static func node(_ node: RenderNode) -> Self { .init(nodes: [node]) }

  /// Transforms each top-level element while leaving other node kinds unchanged.
  ///
  /// Nested elements are not traversed.
  ///
  /// - Parameter transform: A closure that returns the replacement for each top-level element.
  /// - Returns: Content with the transformed top-level elements in their original positions.
  public func mapTopLevelElements(
    _ transform: (RenderElement) -> RenderElement
  ) -> ComponentContent {
    .init(
      nodes: nodes.map { node in
        guard case .element(let element) = node.storage else { return node }
        return .init(storage: .element(transform(element)))
      })
  }
}
