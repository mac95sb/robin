/// A type that declares a render tree with the ``RenderBuilder`` DSL.
///
/// Conforming types describe their view in ``body`` and call ``resolve()`` to
/// obtain a concrete ``RenderNode`` tree for validation and rendering.
public protocol ValidationComponent: Sendable {
  /// The component's view, declared with the ``RenderBuilder`` DSL.
  @RenderBuilder var body: [RenderNode] { get }
}

extension ValidationComponent {
  /// Flattens the component's ``body`` into a single render node.
  ///
  /// - Returns: ``body`` wrapped in a ``RenderNode/fragment(_:)``.
  public func resolve() -> RenderNode { .fragment(body) }
}
