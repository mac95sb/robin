import Foundation

/// One event in a `text/event-stream` response.
public struct ServerSentEvent: Equatable, Sendable {
  /// Event payload. Newlines are emitted as multiple `data` fields.
  public let data: String
  /// Optional event type.
  public let event: String?
  /// Optional stream event identifier.
  public let id: String?
  /// Optional nonnegative client reconnection delay.
  public let retry: Duration?

  /// Creates one server-sent event.
  public init(
    data: String,
    event: String? = nil,
    id: String? = nil,
    retry: Duration? = nil
  ) {
    precondition(event?.contains(where: { $0.isNewline }) != true)
    precondition(id?.contains(where: { $0.isNewline }) != true)
    precondition(retry.map { $0 >= .zero } ?? true)
    self.data = data
    self.event = event
    self.id = id
    self.retry = retry
  }

  package var encoded: [UInt8] {
    var lines: [String] = []
    if let event { lines.append("event: \(event)") }
    if let id { lines.append("id: \(id)") }
    if let retry {
      let components = retry.components
      let milliseconds =
        components.seconds * 1_000 + components.attoseconds / 1_000_000_000_000_000
      lines.append("retry: \(milliseconds)")
    }
    lines += data.replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .split(separator: "\n", omittingEmptySubsequences: false).map { "data: \($0)" }
    return Array((lines.joined(separator: "\n") + "\n\n").utf8)
  }
}
