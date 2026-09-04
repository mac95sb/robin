/// An external translation-management integration.
public protocol TranslationProvider: Sendable {
  /// Pulls current translations for a locale.
  func pull(locale: String) async throws -> [LocalizedStringKey: LocalizedMessage]

  /// Pushes source-locale messages for translation.
  func push(
    _ messages: [LocalizedStringKey: LocalizedMessage],
    sourceLocale: String
  ) async throws
}

extension LocalizationCatalog {
  /// Pulls configured locales from an external translation-management provider.
  public static func pulling(
    locales: [String],
    from provider: some TranslationProvider
  ) async throws -> Self {
    var translations: [String: [LocalizedStringKey: LocalizedMessage]] = [:]
    for locale in locales {
      translations[locale] = try await provider.pull(locale: locale)
    }
    return Self(translations)
  }

  /// Pushes one source locale to an external translation-management provider.
  public func push(sourceLocale: String, to provider: some TranslationProvider) async throws {
    guard let messages = translations[sourceLocale] else { return }
    try await provider.push(messages, sourceLocale: sourceLocale)
  }
}
