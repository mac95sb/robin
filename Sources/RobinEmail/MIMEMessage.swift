import Foundation

/// Deterministic UTF-8 MIME serialization for SMTP transports and tests.
public struct MIMEMessage {
  private init() {}

  /// Serializes a multipart plain-text and HTML message.
  public static func serialize(_ message: EmailMessage) -> Data {
    let boundary = "robin-\(message.id.replacingOccurrences(of: "-", with: ""))"
    var headers = [
      "Message-ID: <\(message.id)@robin.local>",
      "From: \(message.from.header)",
      "To: \(message.to.map(\.header).joined(separator: ", "))",
      "Subject: =?UTF-8?B?\(Data(message.subject.utf8).base64EncodedString())?=",
      "MIME-Version: 1.0",
      "Content-Type: multipart/alternative; boundary=\"\(boundary)\"",
    ]
    if !message.cc.isEmpty {
      headers.insert("Cc: \(message.cc.map(\.header).joined(separator: ", "))", at: 3)
    }
    if let replyTo = message.replyTo { headers.insert("Reply-To: \(replyTo.header)", at: 2) }
    let text = Data(message.text.utf8).base64EncodedString(options: .lineLength76Characters)
      .replacingOccurrences(of: "\n", with: "\r\n")
    let html = Data(message.html.utf8).base64EncodedString(options: .lineLength76Characters)
      .replacingOccurrences(of: "\n", with: "\r\n")
    let body = """
      --\(boundary)\r
      Content-Type: text/plain; charset=utf-8\r
      Content-Transfer-Encoding: base64\r
      \r
      \(text)\r
      --\(boundary)\r
      Content-Type: text/html; charset=utf-8\r
      Content-Transfer-Encoding: base64\r
      \r
      \(html)\r
      --\(boundary)--\r
      """
    return Data((headers.joined(separator: "\r\n") + "\r\n\r\n" + body).utf8)
  }
}
