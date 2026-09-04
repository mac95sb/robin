/// A deterministic local translation catalog.
public struct LocalizationCatalog: Sendable {
  package let translations: [String: [LocalizedStringKey: LocalizedMessage]]

  /// Creates a catalog keyed by configured locale identifier.
  public init(_ translations: [String: [LocalizedStringKey: LocalizedMessage]]) {
    self.translations = translations
  }

  /// Resolves a message, optionally selecting and interpolating a plural form.
  public func string(_ key: LocalizedStringKey, locale: String, count: Int? = nil) -> String? {
    precondition(count.map { $0 >= 0 } ?? true)
    return translations[locale]?[key]?.resolve(locale: locale, count: count)
  }

  /// Reports every required translation missing from a configured locale.
  public func diagnostics(required keys: Set<LocalizedStringKey>) -> [LocalizationDiagnostic] {
    translations.keys.sorted().flatMap { locale in
      keys.subtracting(Set(translations[locale, default: [:]].keys)).sorted {
        $0.value < $1.value
      }
      .map { .missing(locale: locale, key: $0) }
    }
  }
}
