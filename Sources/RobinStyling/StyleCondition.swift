/// Whether a component in the ancestor chain declared typed containment for a style's container
/// condition to resolve against.
public enum ContainmentContext: Equatable, Sendable {
  /// No ancestor in the current prototype context declared containment.
  case none
  /// An ancestor declared containment (the prototype stand-in for `.containerType(.inlineSize)`).
  case declared
}

/// A prototype CSS-cascade condition for a typed style.
public enum StyleCondition: Equatable, Hashable, Sendable {
  /// Applies the declarations without a conditional selector or query.
  case always

  /// Applies the declarations when the element matches a `:has()` relational selector.
  ///
  /// - Parameter selector: The raw selector passed to `:has(...)`.
  case has(String)

  /// Applies the declarations at or above a minimum inline-size, scoped to the nearest
  /// containment ancestor via `@container`.
  case containerMinWidth(Int)

  /// Applies the declarations at or above a minimum viewport width via `@media`.
  case pageMinWidth(Int)

  /// Applies the declarations as the element's before-state for a discrete or otherwise
  /// non-interpolable property transition, via `@starting-style`.
  case startingStyle

  /// A stable, explicit textual key used to derive deterministic generated class names.
  var canonicalKey: String {
    switch self {
    case .always: "always"
    case .has(let selector): "has:\(selector)"
    case .containerMinWidth(let width): "container:\(width)"
    case .pageMinWidth(let width): "page:\(width)"
    case .startingStyle: "starting-style"
    }
  }
}
