@_spi(Rendering) import RobinCore

/// The single entry point for a Robin application, analogous to SwiftUI's `App`.
///
/// `Application` declares site-level ``Metadata`` defaults and the application's routable pages.
/// Robin infers the application's rendering mode exclusively from the resolved page and
/// controller registrations; application code never declares or overrides a mode.
///
/// RobinHTML resolves the static-site half of that inference — one or more registered pages.
/// Controller-route registration, and the resulting API/SSR modes, are established once the
/// application depends on `RobinRouting`; an `Application` conforming here always resolves to
/// ``ApplicationMode/static``.
public protocol Application: Sendable {
  /// The concrete type produced by ``pages``.
  associatedtype PagesBody: Pages = EmptyPages
  associatedtype RoutesBody: Routes = EmptyRoutes

  /// Site-level metadata defaults that every ``Page`` overlays.
  var metadata: Metadata { get }
  var theme: any ApplicationTheme { get }

  /// The client-side navigation strategy for a Static Site application.
  ///
  /// The default, ``ClientNavigation/automatic``, ships no client navigation runtime.
  var clientNavigation: ClientNavigation { get }

  /// The application's routable pages.
  @PagesBuilder var pages: PagesBody { get }
  @RoutesBuilder var routes: RoutesBody { get }
}

extension Application {
  /// The default client navigation strategy: no runtime chunk ships.
  public var clientNavigation: ClientNavigation { .automatic }
  public var theme: any ApplicationTheme { DefaultApplicationTheme() }
}

extension Application where PagesBody == EmptyPages {
  /// The default empty page registration.
  public var pages: EmptyPages { EmptyPages() }
}

extension Application where RoutesBody == EmptyRoutes {
  public var routes: EmptyRoutes { EmptyRoutes() }
}

extension Application {
  /// The rendering mode inferred from the application's resolved pages.
  ///
  /// - Throws: ``ApplicationCompositionError/empty`` when the application registers no pages.
  public var mode: ApplicationMode {
    get throws {
      try ApplicationMode(hasViews: !pages.pages.isEmpty, hasControllers: !routes.routes.isEmpty)
    }
  }
}
