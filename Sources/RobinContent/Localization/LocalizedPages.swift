import Foundation
import RobinCore
import RobinHTML

/// Registers pages once for every supported locale.
///
/// Robin reads the locales from `Localizable.xcstrings`. Each registered page receives a
/// locale-prefixed path, canonical and alternate-language metadata, and an automatic localization
/// context for calls to ``t(_:)``.
public struct LocalizedPages: Pages {
  /// The locale-expanded pages in deterministic locale and declaration order.
  public let pages: [any Page]

  /// Creates localized copies of a page collection.
  ///
  /// - Parameters:
  ///   - bundle: The bundle containing the application's string catalog.
  ///   - baseURL: The absolute site URL used for canonical and alternate links.
  ///   - pages: Pages to register for every locale.
  /// - Precondition: `bundle` contains a nonempty `Localizable.xcstrings` resource and `baseURL`
  ///   is an absolute HTTP or HTTPS URL.
  public init(
    bundle: Bundle,
    baseURL: URL,
    @PagesBuilder pages: () -> PageList
  ) {
    guard let catalog = LocalizationCatalog(xcstringsIn: bundle), !catalog.locales.isEmpty else {
      preconditionFailure("LocalizedPages requires a nonempty Localizable.xcstrings resource.")
    }
    let pages = pages().pages
    self.pages = catalog.locales.flatMap { locale in
      pages.map {
        LocalizedPage(
          $0,
          locale: locale,
          locales: catalog.locales,
          catalog: catalog,
          baseURL: baseURL)
      }
    }
  }
}

private struct LocalizedPage: Page {
  let path: String
  private let page: any Page
  private let locale: String
  private let locales: [String]
  private let catalog: LocalizationCatalog
  private let baseURL: URL?

  init(
    _ page: any Page,
    locale: String,
    locales: [String],
    catalog: LocalizationCatalog,
    baseURL: URL?
  ) {
    self.page = page
    self.locale = locale
    self.locales = locales
    self.catalog = catalog
    self.baseURL = baseURL
    self.path =
      baseURL.map {
        LocalizedRouteSet(baseURL: $0, path: page.path, locales: locales).path(for: locale)
      } ?? "/\(locale)" + (page.path == "/" ? "" : page.path)
  }

  var metadata: Metadata {
    withLocalization(locale: locale, catalog: catalog) {
      guard let baseURL else {
        var metadata = page.metadata
        metadata.language = locale
        return metadata
      }
      return LocalizedRouteSet(baseURL: baseURL, path: page.path, locales: locales)
        .metadata(page.metadata, for: locale)
    }
  }

  var body: ComponentContent {
    withLocalization(locale: locale, catalog: catalog) { page.body }
  }
}

extension LocalizedPages {
  /// Resolves locale-prefixed pages when the application target bundles a string catalog.
  ///
  /// Applications register pages directly. A nonempty `Localizable.xcstrings` resource in the
  /// application's SwiftPM resource bundle supplies the supported locales and the context used by
  /// ``t(_:)``.
  public static func automatic<Application: App>(_ application: Application) -> [any Page] {
    guard let bundle = application.resourceBundle,
      let catalog = LocalizationCatalog(xcstringsIn: bundle), !catalog.locales.isEmpty
    else {
      return application.pages.pages
    }
    return catalog.locales.flatMap { locale in
      application.pages.pages.map {
        LocalizedPage(
          $0, locale: locale, locales: catalog.locales, catalog: catalog, baseURL: nil)
      }
    }
  }

}
