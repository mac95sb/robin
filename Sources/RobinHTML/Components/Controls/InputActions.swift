import RobinRuntime

extension Input {
  /// Runs an action after the native `change` event commits a valid user edit.
  /// Bound state is updated first. Programmatic state changes and form resets do not fire this handler.
  /// - Parameter action: A reusable browser-local action, commonly built with `#action`.
  /// - Returns: The input with a change handler.
  public func onChange(action: StateAction) -> Input {
    var input = self
    input.changeAction = action
    return input
  }

  /// Runs an action after each valid native `input` edit, after updating bound state.
  /// Unlike `onChange(action:)`, typing does not wait for the field to lose focus.
  /// - Parameter action: A reusable browser-local action.
  /// - Returns: The input with an input handler.
  public func onInput(action: StateAction) -> Input {
    var input = self
    input.inputAction = action
    return input
  }
}
