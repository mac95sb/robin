import Foundation
import RobinBuild

/// A typed browser module that binds one form to a same-origin WebSocket.
public struct WebSocketClientModule: Sendable {
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
  public init(
    path: String,
    formID: String,
    inputID: String,
    messagesID: String,
    statusID: String
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
    let configuration = try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
    return #"""
      const config=\#(configuration),form=document.getElementById(config.formID),input=document.getElementById(config.inputID),messages=document.getElementById(config.messagesID),status=document.getElementById(config.statusID);
      if(form&&input&&messages&&status){const scheme=location.protocol==="https:"?"wss":"ws",socket=new WebSocket(`${scheme}://${location.host}${config.path}`);socket.addEventListener("open",()=>status.textContent="Connected");socket.addEventListener("close",()=>status.textContent="Disconnected");socket.addEventListener("error",()=>status.textContent="Connection error");socket.addEventListener("message",event=>{const item=document.createElement("li");item.textContent=event.data;messages.append(item)});form.addEventListener("submit",event=>{event.preventDefault();const value=input.value.trim();if(value&&socket.readyState===WebSocket.OPEN){socket.send(value);input.value=""}})};
      """#
  }
}

extension WebSocketClientModule: Encodable {
  private enum CodingKeys: String, CodingKey { case path, formID, inputID, messagesID, statusID }
}
