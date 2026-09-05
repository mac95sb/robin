/// A concrete, order-preserving page registration produced by ``PagesBuilder``.
public struct PageList: Pages {
  public let pages: [any Page]
}
