import Foundation

/// Cardinal plural variants for a localized message.
public struct LocalizedMessage: Sendable {
  /// Variants selected by the locale's cardinal rules.
  public enum Plural: Hashable, Sendable {
    /// The locale's zero form.
    case zero
    /// The locale's singular form.
    case one
    /// The locale's dual form.
    case two
    /// The locale's few form.
    case few
    /// The locale's many form.
    case many
    /// The required fallback form.
    case other
  }

  private let text: String?
  private let plurals: [Plural: String]

  /// Creates an uncounted message.
  public static func text(_ value: String) -> Self { Self(text: value, plurals: [:]) }

  /// Creates a counted message. The `other` form is required and `{count}` is interpolated.
  public static func plural(_ values: [Plural: String]) -> Self {
    precondition(values[.other] != nil)
    return Self(text: nil, plurals: values)
  }

  package func resolve(locale: String, count: Int?) -> String? {
    if let text { return text }
    guard let count else { return nil }
    return (plurals[pluralCategory(count, locale: locale)] ?? plurals[.other])?
      .replacingOccurrences(of: "{count}", with: String(count))
  }
}

private func pluralCategory(_ count: Int, locale: String) -> LocalizedMessage.Plural {
  let language = locale.split(separator: "-").first?.lowercased()
  switch language {
  case "ar":
    if count == 0 { return .zero }
    if count == 1 { return .one }
    if count == 2 { return .two }
    if 3...10 ~= count % 100 { return .few }
    if 11...99 ~= count % 100 { return .many }
    return .other
  case "fr", "pt": return count == 0 || count == 1 ? .one : .other
  default: return count == 1 ? .one : .other
  }
}
