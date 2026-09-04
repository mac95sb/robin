import Foundation
import RobinContent
import RobinCore
import Testing

@Suite("Content localization")
struct LocalizationTests {
  @Test func negotiatesInRequiredPrecedenceAndFormatsRTLContent() {
    let negotiator = LocaleNegotiator(supported: ["en-GB", "fr", "ar"], defaultLocale: "en-GB")

    #expect(
      negotiator.resolve(
        .init(route: "ar", user: "fr", acceptLanguage: "en;q=1")) == "ar")
    #expect(
      negotiator.resolve(
        .init(user: "fr", acceptLanguage: "ar;q=1")) == "fr")
    #expect(
      negotiator.resolve(.init(acceptLanguage: "ar;q=0.5, fr;q=0.9")) == "fr")
    #expect(LocalizationFormatter(locale: "ar").direction == .rightToLeft)
  }

  @Test func resolvesPluralsAndReportsIncompleteLocales() {
    let items: LocalizedStringKey = "items"
    let title: LocalizedStringKey = "title"
    let catalog = LocalizationCatalog([
      "en": [
        items: .plural([.one: "One item", .other: "{count} items"]),
        title: .text("Products"),
      ],
      "fr": [items: .plural([.one: "Un article", .other: "{count} articles"])],
    ])

    #expect(catalog.string(items, locale: "en", count: 1) == "One item")
    #expect(catalog.string(items, locale: "fr", count: 2) == "2 articles")
    #expect(catalog.diagnostics(required: [items, title]) == [.missing(locale: "fr", key: title)])
  }

  @Test func localeRoutesProduceCanonicalAndAlternateMetadata() {
    let routes = LocalizedRouteSet(
      baseURL: URL(string: "https://example.com")!, path: "/guide", locales: ["en", "fr"])
    let metadata = routes.metadata(Metadata(title: "Guide"), for: "fr")

    #expect(routes.path(for: "fr") == "/fr/guide")
    #expect(metadata.language == "fr")
    #expect(metadata.canonicalURL == "https://example.com/fr/guide")
    #expect(metadata.alternateLanguages.map(\.language) == ["en", "fr"])
  }

  @Test func translationProvidersCanPullAndPushCatalogs() async throws {
    let provider = TestTranslationProvider()
    let catalog = try await LocalizationCatalog.pulling(locales: ["en"], from: provider)

    #expect(catalog.string("title", locale: "en") == "Robin")
    try await catalog.push(sourceLocale: "en", to: provider)
    #expect(await provider.pushedKeys() == ["title"])
  }
}

private actor TestTranslationProvider: TranslationProvider {
  private var pushed: [LocalizedStringKey] = []

  func pull(locale _: String) -> [LocalizedStringKey: LocalizedMessage] {
    ["title": .text("Robin")]
  }

  func push(
    _ messages: [LocalizedStringKey: LocalizedMessage], sourceLocale _: String
  ) {
    pushed = messages.keys.sorted { $0.value < $1.value }
  }

  func pushedKeys() -> [String] { pushed.map(\.value) }
}
