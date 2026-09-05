import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Drives a local browser through the W3C WebDriver HTTP protocol.
public actor BrowserSession {
  private static let elementKey = "element-6066-11e4-a52e-4f735466cecf"
  private let endpoint: URL
  private let sessionID: String
  private let urlSession: URLSession

  private init(endpoint: URL, sessionID: String, urlSession: URLSession) {
    self.endpoint = endpoint
    self.sessionID = sessionID
    self.urlSession = urlSession
  }

  /// Starts a loopback-only WebDriver session.
  ///
  /// - Parameters:
  ///   - endpoint: The local WebDriver server URL.
  ///   - profile: Browser, JavaScript, viewport, and locale settings.
  /// - Returns: A ready browser session.
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public static func start(
    at endpoint: URL,
    profile: BrowserTestProfile
  ) async throws -> BrowserSession {
    guard endpoint.scheme == "http",
      endpoint.user == nil, endpoint.password == nil, endpoint.query == nil,
      endpoint.fragment == nil,
      ["127.0.0.1", "::1", "localhost"].contains(endpoint.host?.lowercased() ?? "")
    else { throw BrowserSessionError.unsafeEndpoint(endpoint.absoluteString) }
    guard profile.browser != .safari || profile.javaScriptEnabled else {
      throw BrowserSessionError.unsupportedProfile(
        "Safari WebDriver cannot guarantee a JavaScript-disabled session.")
    }
    let urlSession = URLSession(configuration: .ephemeral)
    let body: [String: Any] = [
      "capabilities": [
        "alwaysMatch": capabilities(for: profile)
      ]
    ]
    let value = try await request(
      endpoint.appendingPathComponent("session"),
      method: "POST",
      body: body,
      session: urlSession
    )
    guard let sessionID = sessionIdentifier(in: value) else {
      throw BrowserSessionError.invalidResponse
    }
    let browser = BrowserSession(endpoint: endpoint, sessionID: sessionID, urlSession: urlSession)
    try await browser.setViewport(width: profile.width, height: profile.height)
    return browser
  }

  /// Navigates to an absolute HTTP or HTTPS URL.
  ///
  /// - Parameter url: The page to load.
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public func navigate(to url: URL) async throws {
    guard ["http", "https"].contains(url.scheme ?? ""), url.host != nil else {
      throw BrowserSessionError.commandFailed("Navigation requires an absolute HTTP URL.")
    }
    _ = try await command("url", method: "POST", body: ["url": url.absoluteString])
  }

  /// Returns the current serialized document source.
  ///
  /// - Returns: The browser's current page source.
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public func pageSource() async throws -> String {
    let value = try await command("source")
    guard let source = value["value"] as? String else { throw BrowserSessionError.invalidResponse }
    return source
  }

  /// Captures the current viewport as PNG data.
  ///
  /// - Returns: Decoded PNG bytes.
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public func screenshot() async throws -> Data {
    let value = try await command("screenshot")
    guard let encoded = value["value"] as? String, let data = Data(base64Encoded: encoded) else {
      throw BrowserSessionError.invalidResponse
    }
    return data
  }

  /// Activates an element through keyboard input rather than pointer-only behavior.
  ///
  /// - Parameter identifier: The element's document-wide `id` value.
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public func activate(elementWithID identifier: String) async throws {
    guard Self.isValidElementIdentifier(identifier) else {
      throw BrowserSessionError.invalidElementIdentifier(identifier)
    }
    let found = try await command(
      "element",
      method: "POST",
      body: ["using": "css selector", "value": "#\(identifier)"]
    )
    guard let value = found["value"] as? [String: Any],
      let element = value[Self.elementKey] as? String
    else { throw BrowserSessionError.invalidResponse }
    _ = try await command(
      "element/\(element)/value",
      method: "POST",
      body: ["text": "\u{E007}", "value": ["\u{E007}"]]
    )
  }

  /// Ends the browser session.
  ///
  /// - Throws: ``BrowserSessionError`` or a networking error.
  public func close() async throws {
    _ = try await command("", method: "DELETE")
  }

  private func setViewport(width: Int, height: Int) async throws {
    _ = try await command(
      "window/rect",
      method: "POST",
      body: ["width": width, "height": height]
    )
  }

  private func command(
    _ path: String,
    method: String = "GET",
    body: [String: Any]? = nil
  ) async throws -> [String: Any] {
    let url = endpoint.appendingPathComponent("session/\(sessionID)/\(path)")
    return try await Self.request(url, method: method, body: body, session: urlSession)
  }

  private static func capabilities(for profile: BrowserTestProfile) -> [String: Any] {
    var capabilities: [String: Any] = [
      "browserName": profile.browser.rawValue,
      "acceptInsecureCerts": false,
    ]
    switch profile.browser {
    case .chrome:
      capabilities["goog:chromeOptions"] = [
        "prefs": [
          "intl.accept_languages": profile.locale,
          "profile.managed_default_content_settings.javascript": profile.javaScriptEnabled ? 1 : 2,
        ]
      ]
    case .firefox:
      capabilities["moz:firefoxOptions"] = [
        "prefs": [
          "intl.accept_languages": profile.locale,
          "javascript.enabled": profile.javaScriptEnabled,
        ]
      ]
    case .safari: break
    }
    return capabilities
  }

  package static func sessionIdentifier(in response: [String: Any]) -> String? {
    (response["value"] as? [String: Any])?["sessionId"] as? String
  }

  package static func isValidElementIdentifier(_ identifier: String) -> Bool {
    identifier.first?.isLetter == true
      && identifier.allSatisfy { $0.isLetter || $0.isNumber || "-_".contains($0) }
  }

  private static func request(
    _ url: URL,
    method: String,
    body: [String: Any]? = nil,
    session: URLSession
  ) async throws -> [String: Any] {
    var request = URLRequest(url: url)
    request.httpMethod = method
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw BrowserSessionError.invalidResponse }
    let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    guard (200..<300).contains(http.statusCode) else {
      let value = object["value"] as? [String: Any]
      throw BrowserSessionError.commandFailed(
        value?["message"] as? String ?? "WebDriver returned HTTP \(http.statusCode)."
      )
    }
    return object
  }
}
