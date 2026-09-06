import Foundation
import RobinBuild

/// A typed browser module that binds one form to a same-origin WebSocket.
///
/// Register one binding per document. Incoming messages append plain-text list items;
/// outgoing values are trimmed text. The module reports disconnections without retrying
/// or replaying messages. Reload the page to reconnect.
public struct WebSocketClientModule: Sendable {
  /// The server-to-browser message representation.
  public enum MessageFormat: String, Codable, Sendable {
    /// Plain text rendered as a list item.
    case text
    /// A JSON-encoded ``Message`` with optional supplementary hover text.
    case json
  }

  /// A text message with an optional native tooltip. Both fields render as plain text.
  public struct Message: Codable, Sendable {
    /// The visible message.
    public let text: String
    /// Supplementary text displayed on hover.
    public let title: String?

    /// Creates a message for a binding configured with ``MessageFormat/json``.
    public init(text: String, title: String? = nil) {
      self.text = text
      self.title = title
    }
  }

  /// The representation expected for incoming messages; outgoing form values remain plain text.
  public let messageFormat: MessageFormat
  /// Same-origin WebSocket endpoint.
  public let path: String
  /// Identifier of the form that sends messages.
  public let formID: String
  /// Identifier of the text input sent by the form.
  public let inputID: String
  /// Identifier of the list that receives messages.
  public let messagesID: String
  /// Identifier of the text element that reports connection state.
  public let statusID: String

  /// Creates a validated WebSocket binding.
  /// - Parameters:
  ///   - path: An absolute same-origin endpoint path without a query, fragment, or dot segments.
  ///   - formID: The sending form's unique identifier.
  ///   - inputID: The text input's unique identifier.
  ///   - messagesID: The receiving list's unique identifier.
  ///   - statusID: The connection-status element's unique identifier.
  ///   - messageFormat: The incoming representation; outgoing messages remain plain text.
  /// - Throws: ``WebSocketClientModuleError/invalidConfiguration`` for an invalid path
  ///   or identifiers that are empty, contain whitespace, or are not distinct.
  public init(
    path: String,
    formID: String,
    inputID: String,
    messagesID: String,
    statusID: String,
    messageFormat: MessageFormat = .text
  ) throws {
    let identifiers = [formID, inputID, messagesID, statusID]
    let pathSegments = path.split(separator: "/", omittingEmptySubsequences: false)
    guard path.hasPrefix("/"), !path.hasPrefix("//"), !path.contains("\\"),
      !path.contains("?"), !path.contains("#"),
      pathSegments.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
      identifiers.allSatisfy({ !$0.isEmpty && !$0.contains(where: \.isWhitespace) }),
      Set(identifiers).count == identifiers.count
    else { throw WebSocketClientModuleError.invalidConfiguration }
    self.path = path
    self.formID = formID
    self.inputID = inputID
    self.messagesID = messagesID
    self.statusID = statusID
    self.messageFormat = messageFormat
  }

  /// Returns the capability-scoped browser asset.
  public func asset() throws -> BuildAsset {
    try BuildAsset(
      reference: "/robin/websocket.js",
      path: "assets/robin-websocket.js",
      bytes: Array(try source().utf8),
      mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.stream, selectedBy: "WebSocketClientModule"))
  }

  private func source() throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let configuration = try String(decoding: encoder.encode(self), as: UTF8.self)
    return #"""
      const config=\#(configuration),form=document.getElementById(config.formID),input=document.getElementById(config.inputID),messages=document.getElementById(config.messagesID),status=document.getElementById(config.statusID);
      if(form&&input&&messages&&status){const scheme=location.protocol==="https:"?"wss":"ws",socket=new WebSocket(`${scheme}://${location.host}${config.path}`);socket.addEventListener("open",()=>status.textContent="Connected");socket.addEventListener("close",()=>status.textContent="Disconnected");socket.addEventListener("error",()=>status.textContent="Connection error");socket.addEventListener("message",event=>{
        let message={text:event.data};
        if(config.messageFormat==="json"){
          try{message=JSON.parse(event.data)}catch{status.textContent="Invalid message";return}
          if(!message||typeof message.text!=="string"||(message.title!=null&&typeof message.title!=="string")){status.textContent="Invalid message";return}
        }
        const item=document.createElement("li");item.textContent=message.text;if(message.title)item.title=message.title;messages.append(item)
      });form.addEventListener("submit",event=>{event.preventDefault();const value=input.value.trim();if(value&&socket.readyState===WebSocket.OPEN){socket.send(value);input.value=""}})};
      """#
  }
}

extension WebSocketClientModule: Encodable {
  private enum CodingKeys: String, CodingKey {
    case path, formID, inputID, messagesID, statusID, messageFormat
  }
}
