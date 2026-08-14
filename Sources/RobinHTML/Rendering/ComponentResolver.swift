/// Resolves typed components into the structural representation consumed by renderers.
public enum ComponentResolver {
  /// Resolves a component tree while preserving child source order.
  ///
  /// - Parameter component: The root component to resolve.
  /// - Returns: A fragment node containing the component's resolved body nodes.
  public static func resolve<C: Component>(_ component: C) -> RenderNode {
    .init(storage: .fragment(component.body.nodes))
  }
}
