extension StructuredData {
  /// An ordered trail showing the page's place in the site hierarchy.
  public struct BreadcrumbList: Equatable, Sendable {
    /// The ordered breadcrumb items, starting at the site root.
    public let items: [Breadcrumb]

    /// Creates a breadcrumb list.
    ///
    /// - Parameter items: At least one ordered breadcrumb.
    public init(_ items: [Breadcrumb]) {
      precondition(!items.isEmpty)
      self.items = items
    }
  }

  /// One named destination in a breadcrumb trail.
  public struct Breadcrumb: Equatable, Sendable {
    /// The label visible on the page.
    public let name: String
    /// The absolute URL for this position.
    public let url: String

    /// Creates a breadcrumb.
    public init(_ name: String, url: String) {
      self.name = name
      self.url = url
    }
  }
}
