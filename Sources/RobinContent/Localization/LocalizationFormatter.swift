import Foundation

/// Locale-aware number, currency, and date formatting.
public struct LocalizationFormatter: Sendable {
  /// Resolved locale identifier.
  public let locale: String

  /// Creates a formatter for one resolved locale.
  public init(locale: String) { self.locale = locale }

  /// Direction token suitable for the HTML `dir` attribute.
  public var direction: TextDirection {
    let rtl = ["ar", "dv", "fa", "he", "ku", "ps", "ur", "yi"]
    return rtl.contains(String(locale.split(separator: "-").first ?? ""))
      ? .rightToLeft : .leftToRight
  }

  /// Formats a decimal number.
  public func number(_ value: Decimal) -> String {
    format(value, style: .decimal)
  }

  /// Formats a currency using its ISO code.
  public func currency(_ value: Decimal, code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.locale = Locale(identifier: locale)
    return formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
  }

  /// Formats a date with native locale rules.
  public func date(_ value: Date, dateStyle: DateFormatter.Style = .medium) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: locale)
    formatter.dateStyle = dateStyle
    formatter.timeStyle = .none
    return formatter.string(from: value)
  }

  private func format(_ value: Decimal, style: NumberFormatter.Style) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = style
    formatter.locale = Locale(identifier: locale)
    return formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
  }
}
