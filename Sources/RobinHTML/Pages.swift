/// A typed collection of routable ``Page`` values registered by an ``App``.
public protocol Pages: Sendable {
  /// The registered pages in source order.
  var pages: [any Page] { get }
}

/// An empty page registration.
///
/// The default for an ``App`` that registers no pages.
public struct EmptyPages: Pages {
  public let pages: [any Page] = []

  /// Creates an empty page registration.
  public init() {}
}

/// A concrete, order-preserving page registration produced by ``PagesBuilder``.
public struct PageList: Pages {
  public let pages: [any Page]
}

/// Builds page registrations with native Swift conditionals and loops.
@resultBuilder
public struct PagesBuilder {
  /// Resolves a single page into a one-element registration.
  ///
  /// - Parameter expression: The page to register.
  /// - Returns: A registration containing only `expression`.
  public static func buildExpression<P: Page>(_ expression: P) -> PageList {
    PageList(pages: [expression])
  }

  /// Resolves a page group into its prefixed pages.
  ///
  /// - Parameter expression: The page group to register.
  /// - Returns: The group's pages in source order.
  public static func buildExpression(_ expression: PageGroup) -> PageList {
    PageList(pages: expression.pages)
  }

  /// Resolves a page collection into its registrations.
  ///
  /// - Parameter expression: The page collection to register.
  /// - Returns: A registration containing the collection's pages.
  public static func buildExpression<PageCollection: Pages>(_ expression: PageCollection)
    -> PageList
  {
    PageList(pages: expression.pages)
  }

  /// Combines page registrations in source order.
  ///
  /// - Parameter components: The registrations in the block.
  /// - Returns: A flattened registration.
  public static func buildBlock(_ components: PageList...) -> PageList {
    PageList(pages: components.flatMap(\.pages))
  }

  /// Builds a registration for an optional branch.
  ///
  /// - Parameter component: The branch registration, or `nil` when the branch is absent.
  /// - Returns: The branch registration or an empty registration.
  public static func buildOptional(_ component: PageList?) -> PageList {
    component ?? PageList(pages: [])
  }

  /// Builds the first branch of a conditional.
  ///
  /// - Parameter component: The selected branch registration.
  /// - Returns: The supplied registration.
  public static func buildEither(first component: PageList) -> PageList { component }

  /// Builds the second branch of a conditional.
  ///
  /// - Parameter component: The selected branch registration.
  /// - Returns: The supplied registration.
  public static func buildEither(second component: PageList) -> PageList { component }

  /// Combines registrations produced by a loop.
  ///
  /// - Parameter components: The registrations produced by the loop.
  /// - Returns: A flattened registration in iteration order.
  public static func buildArray(_ components: [PageList]) -> PageList {
    PageList(pages: components.flatMap(\.pages))
  }

  /// Passes availability-gated content through the builder.
  ///
  /// - Parameter component: The registration available on the current platform.
  /// - Returns: The supplied registration.
  public static func buildLimitedAvailability(_ component: PageList) -> PageList { component }
}
