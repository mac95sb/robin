import RobinCore

/// A path prefix shared by a group of pages.
///
/// Groups can contain other groups. Robin joins their prefixes in declaration order.
///
/// ```swift
/// PageGroup("docs") {
///   PageGroup("guides") { GuidePage() }
/// }
/// ```
public struct PageGroup: Sendable {
  package let pages: [any Page]

  /// Creates a page group.
  ///
  /// - Parameters:
  ///   - prefix: The path prefix applied to the group's pages.
  ///   - pages: The pages or nested groups in this group.
  public init(_ prefix: String, @PagesBuilder pages: () -> PageList) {
    let segments = prefix.split(separator: "/").map(String.init)
    precondition(
      !segments.isEmpty && !segments.contains(".") && !segments.contains(".."),
      "A page group prefix must contain a path segment and cannot traverse directories."
    )
    let prefix = "/" + segments.joined(separator: "/")
    self.pages = pages().pages.map { GroupedPage(prefix: prefix, page: $0) }
  }
}

private struct GroupedPage: Page {
  let path: String
  let metadata: Metadata
  let body: ComponentContent

  init(prefix: String, page: any Page) {
    path = prefix + (page.path == "/" ? "" : "/" + page.path.drop(while: { $0 == "/" }))
    metadata = page.metadata
    body = page.body
  }
}
