import Foundation

/// A deterministic local translation catalog.
public struct LocalizationCatalog: Sendable {
  package let translations: [String: [LocalizedStringKey: LocalizedMessage]]
  package var locales: [String] { translations.keys.sorted() }

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

extension LocalizationCatalog {
  package init?(xcstringsIn bundle: Bundle) {
    guard let url = bundle.url(forResource: "Localizable", withExtension: "xcstrings"),
      let data = try? Data(contentsOf: url),
      let catalog = try? JSONDecoder().decode(StringCatalog.self, from: data)
    else { return nil }

    var translations: [String: [LocalizedStringKey: LocalizedMessage]] = [:]
    for (key, entry) in catalog.strings {
      for (locale, localization) in entry.localizations {
        // ponytail: decode variations when a generated template needs catalog plurals.
        guard let stringUnit = localization.stringUnit else { continue }
        translations[locale, default: [:]][LocalizedStringKey(key)] =
          .text(stringUnit.value)
      }
    }
    self.init(translations)
  }
}

private struct StringCatalog: Decodable {
  let strings: [String: Entry]

  struct Entry: Decodable {
    let localizations: [String: Localization]

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      localizations =
        try container.decodeIfPresent(
          [String: Localization].self, forKey: .localizations) ?? [:]
    }

    private enum CodingKeys: String, CodingKey { case localizations }
  }

  struct Localization: Decodable {
    let stringUnit: StringUnit?
  }

  struct StringUnit: Decodable {
    let value: String
  }
}
