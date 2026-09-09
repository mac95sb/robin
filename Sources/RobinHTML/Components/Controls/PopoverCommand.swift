/// A standard browser command for the enclosing native popover.
public enum PopoverCommand: Equatable, Sendable {
  /// Closes the enclosing popover.
  case dismiss

  var value: String {
    switch self {
    case .dismiss: "hide-popover"
    }
  }
}
