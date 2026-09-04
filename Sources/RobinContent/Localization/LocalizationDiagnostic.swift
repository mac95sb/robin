/// Missing or inconsistent translation state.
public enum LocalizationDiagnostic: Equatable, Sendable {
  /// A configured locale lacks a required key.
  case missing(locale: String, key: LocalizedStringKey)
}
