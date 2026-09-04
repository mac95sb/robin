private struct LocalizationContext: Sendable {
  let locale: String
  let catalog: LocalizationCatalog
}

private enum LocalizationValues {
  @TaskLocal static var current: LocalizationContext?
}

/// Resolves a key from the current page's string catalog and locale.
///
/// Outside a ``LocalizedPages`` registration, the key is returned unchanged.
///
/// - Parameter key: The string-catalog key to resolve.
/// - Returns: The localized value, or the key when no translation exists.
public func t(_ key: LocalizedStringKey) -> String {
  guard let context = LocalizationValues.current else { return key.value }
  return context.catalog.string(key, locale: context.locale) ?? key.value
}

/// Prefixes an absolute page path with the current page locale.
///
/// Outside a ``LocalizedPages`` registration, the path is returned unchanged.
///
/// - Parameter path: An absolute page path.
/// - Returns: The locale-prefixed path, or `path` when no localization context is active.
/// - Precondition: `path` begins with `/`.
public func localizedPath(_ path: String) -> String {
  precondition(path.hasPrefix("/"))
  guard let locale = LocalizationValues.current?.locale else { return path }
  return "/\(locale)" + (path == "/" ? "" : path)
}

func withLocalization<Value>(
  locale: String,
  catalog: LocalizationCatalog,
  operation: () throws -> Value
) rethrows -> Value {
  try LocalizationValues.$current.withValue(
    .init(locale: locale, catalog: catalog), operation: operation)
}
