/// The typed reason a JavaScript artifact is allowed into production output.
public enum ScriptOrigin: Codable, Equatable, Sendable {
  /// A handler for one reachable typed custom command.
  case robinCustomCommand(command: String, selectedBy: String)
  /// A direct Robin browser capability selected by a semantic API.
  case robinDirectCapability(DirectCapability, selectedBy: String)
  /// Generated glue for a provider-neutral runtime contract.
  case hostAdapter(runtime: String, selectedBy: String)
  /// An explicitly declared application script with its documented exception.
  case application(exception: String)

  /// A direct browser capability that can be tree-shaken independently.
  public enum DirectCapability: String, Codable, CaseIterable, Sendable {
    /// Browser API integration.
    case browserAPI
    /// Streaming updates.
    case stream
    /// Enhanced navigation.
    case navigation
    /// Service-worker integration.
    case serviceWorker
    /// Pointer or touch gestures.
    case gesture
    /// Client-owned state.
    case state
  }

  var isValid: Bool {
    switch self {
    case .robinCustomCommand(let command, let selectedBy):
      Self.hasContent(command) && Self.hasContent(selectedBy)
    case .robinDirectCapability(_, let selectedBy): Self.hasContent(selectedBy)
    case .hostAdapter(let runtime, let selectedBy):
      Self.hasContent(runtime) && Self.hasContent(selectedBy)
    case .application(let exception): Self.hasContent(exception)
    }
  }

  private static func hasContent(_ value: String) -> Bool {
    value.contains { !$0.isWhitespace }
  }
}
