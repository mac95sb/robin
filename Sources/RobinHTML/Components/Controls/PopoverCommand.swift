/// A standard browser command targeting a native popover.
public enum PopoverCommand: Equatable, Sendable {
  /// Toggles the popover with the given element identifier.
  case toggle(String)
  /// Opens the popover with the given element identifier.
  case show(String)
  /// Closes the popover with the given element identifier.
  case hide(String)

  var target: String {
    switch self {
    case .toggle(let id), .show(let id), .hide(let id): id
    }
  }
  var value: String {
    switch self {
    case .toggle: "toggle-popover"
    case .show: "show-popover"
    case .hide: "hide-popover"
    }
  }
}
