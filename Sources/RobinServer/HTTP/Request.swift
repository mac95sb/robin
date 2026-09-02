import Foundation
import HTTPTypes

/// A transport-neutral HTTP request passed to Robin application code.
public struct Request: Sendable {
  /// The normalized request method, URL components, and header fields.
  public let head: HTTPRequest
  /// The complete request body.
  public let body: [UInt8]

  /// Creates a normalized request.
  ///
  /// - Parameters:
  ///   - head: The request metadata.
  ///   - body: The complete request body.
  public init(_ head: HTTPRequest, body: [UInt8] = []) {
    self.head = head
    self.body = body
  }

  /// The request method.
  public var method: HTTPRequest.Method { head.method }
  /// The request target supplied by the transport, including any query string.
  public var target: String { head.path ?? "/" }

  /// The percent-encoded path without a query string or fragment.
  public var path: String {
    String(target.prefix { $0 != "?" && $0 != "#" })
  }

  /// The percent-encoded query string without the leading question mark.
  public var query: String? {
    guard let questionMark = target.firstIndex(of: "?") else { return nil }
    let start = target.index(after: questionMark)
    let end = target[start...].firstIndex(of: "#") ?? target.endIndex
    return String(target[start..<end])
  }

  /// Returns the first value for a header field.
  ///
  /// - Parameter name: The case-insensitive field name.
  public func header(_ name: HTTPField.Name) -> String? {
    head.headerFields[name]
  }

  /// Returns the raw value of a named request cookie.
  ///
  /// - Parameter name: The cookie name.
  /// - Returns: The cookie value, or `nil` when it is absent.
  public func cookie(named name: String) -> String? {
    header(.cookie)?
      .split(separator: ";")
      .lazy
      .map { $0.split(separator: "=", maxSplits: 1).map(String.init) }
      .first { $0.count == 2 && $0[0].trimmingCharacters(in: .whitespaces) == name }?
      .last
  }
}
