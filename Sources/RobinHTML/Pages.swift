/// A typed collection of routable ``Page`` values registered by an ``App``.
public protocol Pages: Sendable {
  /// The registered pages in source order.
  var pages: [any Page] { get }
}
