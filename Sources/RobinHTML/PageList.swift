/// A concrete, order-preserving page registration produced by ``PagesBuilder``.
public struct PageList: Pages {
  /// The pages in source order.
  public let pages: [any Page]
}
