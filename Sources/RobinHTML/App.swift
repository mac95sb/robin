import Foundation
@_spi(Rendering) import RobinCore

/// The single entry point for a Robin application, matching SwiftUI's `App` vocabulary.
///
/// `App` declares site-level `Metadata` defaults, routable pages, and controller routes.
/// Robin infers the application's rendering mode exclusively from the resolved page and
/// controller registrations; application code never declares or overrides a mode.
public protocol App: Sendable {
  /// The concrete type produced by ``pages``.
  associatedtype PageRegistration: Pages = EmptyPages
  /// The concrete type produced by ``routes``.
  associatedtype RouteRegistration: Routes = EmptyRoutes

  /// Site-level metadata defaults that every ``Page`` overlays.
  var metadata: Metadata { get }
  /// The application's design theme.
  var theme: any ApplicationTheme { get }

  /// The client-side navigation strategy for a Static Site application.
  ///
  /// The default, ``ClientNavigation/automatic``, ships no client navigation runtime.
  var clientNavigation: ClientNavigation { get }

  /// The application's routable pages.
  @PagesBuilder var pages: PageRegistration { get }
  /// The application's controller-route registrations.
  @RoutesBuilder var routes: RouteRegistration { get }
}

extension App {
  /// Empty site metadata for applications that do not render pages.
  public var metadata: Metadata { Metadata() }
  /// The default client navigation strategy: no runtime chunk ships.
  public var clientNavigation: ClientNavigation { .automatic }
  /// The default unconfigured application theme.
  public var theme: any ApplicationTheme { DefaultApplicationTheme() }
}

@_spi(Rendering)
public func applicationResourceBundle<Application: App>(for _: Application.Type) -> Bundle? {
  guard let executableURL = Bundle.main.executableURL else { return nil }
  let name = executableURL.lastPathComponent
  let module = String(reflecting: Application.self).split(separator: ".").first.map(String.init)
  var directories = [
    executableURL.deletingLastPathComponent(),
    Bundle.main.bundleURL.deletingLastPathComponent(),
  ]
  let arguments = ProcessInfo.processInfo.arguments
  if let flag = arguments.firstIndex(of: "--test-bundle-path"),
    arguments.indices.contains(arguments.index(after: flag)),
    let testBundle = sequence(
      first: URL(fileURLWithPath: arguments[arguments.index(after: flag)]),
      next: { url in
        let parent = url.deletingLastPathComponent()
        return parent == url ? nil : parent
      }
    ).first(where: { $0.pathExtension == "xctest" })
  {
    directories.append(testBundle.deletingLastPathComponent())
  }
  let suffixes = [name, module].compactMap { $0 }.flatMap {
    ["_\($0).bundle", "_\($0).resources"]
  }
  let bundleURL = directories.lazy.compactMap { directory in
    try? FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: [.isDirectoryKey]
    ).first { candidate in
      candidate.hasDirectoryPath && suffixes.contains { candidate.lastPathComponent.hasSuffix($0) }
    }
  }.first
  guard let bundleURL else { return nil }
  return Bundle(url: bundleURL)
}

extension App where PageRegistration == EmptyPages {
  /// The default empty page registration.
  public var pages: EmptyPages { EmptyPages() }
}

extension App where RouteRegistration == EmptyRoutes {
  /// The default empty controller-route registration.
  public var routes: EmptyRoutes { EmptyRoutes() }
}

extension App {
  /// The rendering mode inferred from the application's pages and controller routes.
  ///
  /// - Throws: `ApplicationCompositionError.empty` when the application registers neither.
  public var mode: ApplicationMode {
    get throws {
      try ApplicationMode(hasViews: !pages.pages.isEmpty, hasControllers: !routes.routes.isEmpty)
    }
  }

  /// Resolves the optional client-navigation module after validating the inferred mode.
  @_spi(Rendering)
  public var clientNavigationRuntime: String? {
    get throws {
      guard clientNavigation == .enabled else { return nil }
      let mode = try mode
      guard mode == .static else {
        throw ApplicationCompositionError.clientNavigationRequiresStaticSite(mode)
      }
      return clientNavigation.runtimeModule
    }
  }
}
