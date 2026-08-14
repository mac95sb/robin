/// A value that lowers into Robin's shared structural render representation.
///
/// Conforming types describe their children declaratively in ``body``. Robin resolves that content
/// into ``RenderNode`` values that can be consumed by static and server renderers.
public protocol Component: Sendable {
  /// The component's declarative child content.
  @ViewBuilder var body: ComponentContent { get }
}
