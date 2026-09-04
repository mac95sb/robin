import RobinHTML

/// Native previous/next navigation for a content collection page.
public struct Pagination: Component {
  private let page: ContentPage
  private let basePath: String

  /// Creates navigation for a page in a paginated collection.
  public init(_ page: ContentPage, basePath: String) {
    precondition(basePath.hasPrefix("/"))
    self.page = page
    self.basePath = basePath
  }

  /// Previous/next links and the visible page position.
  public var body: ComponentContent {
    Navigation {
      if let previous = page.previousNumber {
        Link(page.route(basePath: basePath, number: previous)) { "Previous" }
      }
      Text { "Page \(page.number) of \(page.totalPages)" }
      if let next = page.nextNumber {
        Link(page.route(basePath: basePath, number: next)) { "Next" }
      }
    }.body
  }
}
