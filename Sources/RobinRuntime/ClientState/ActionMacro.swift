/// Compiles supported Swift mutations into a reusable browser-local state action.
///
/// ```swift
/// Button(action: #action {
///   count += 10
///   name = "Robin"
///   isHidden.toggle()
/// }) { "Apply" }
/// ```
///
/// Supports assignment, `+=`, `-=`, Boolean `toggle()`, state reads, scalar literals,
/// parentheses, `+`, `-`, and Boolean `!`. String `+` concatenates text.
/// References must name `@State` properties. Loops, branching, arbitrary calls, and
/// interpolation are rejected at compile time. No supplied Swift closure executes on the server.
/// - Parameter body: An ordered sequence of supported state mutations.
/// - Returns: A serializable action that can be reused by controls and input handlers.
@freestanding(expression)
public macro action(_ body: () -> Void) -> StateAction =
  #externalMacro(module: "RobinMacros", type: "StateActionMacro")
