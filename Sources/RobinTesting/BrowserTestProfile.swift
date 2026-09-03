/// Browser settings applied to one WebDriver test session.
public struct BrowserTestProfile: Equatable, Sendable {
  /// A browser supported by the W3C WebDriver protocol.
  public enum Browser: String, Sendable {
    /// Apple Safari.
    case safari
    /// Google Chrome or Chromium.
    case chrome
    /// Mozilla Firefox.
    case firefox
  }

  /// The requested browser.
  public let browser: Browser
  /// Whether application JavaScript may execute.
  public let javaScriptEnabled: Bool
  /// The viewport width in CSS pixels.
  public let width: Int
  /// The viewport height in CSS pixels.
  public let height: Int
  /// The requested locale identifier.
  public let locale: String

  /// Creates a browser test profile.
  ///
  /// - Parameters:
  ///   - browser: The requested browser.
  ///   - javaScriptEnabled: Whether application JavaScript may execute.
  ///   - width: A positive viewport width in CSS pixels.
  ///   - height: A positive viewport height in CSS pixels.
  ///   - locale: A nonempty locale identifier.
  public init(
    browser: Browser,
    javaScriptEnabled: Bool = false,
    width: Int = 1280,
    height: Int = 800,
    locale: String = "en"
  ) {
    precondition(width > 0 && height > 0 && locale.contains { !$0.isWhitespace })
    self.browser = browser
    self.javaScriptEnabled = javaScriptEnabled
    self.width = width
    self.height = height
    self.locale = locale
  }
}
