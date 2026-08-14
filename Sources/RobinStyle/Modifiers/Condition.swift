/// A CSS-cascade condition applied to a grouped style modifier.
///
/// Conditions are compiled into selectors or media queries and do not require
/// client-side runtime state.
public enum Condition: Equatable, Hashable, Sendable {
  /// Applies the declarations without a conditional selector or media query.
  case always

  /// Applies the declarations at or above a tokenized viewport width.
  ///
  /// - Parameter breakpoint: The theme breakpoint resolved to a pixel width at
  ///   style-compilation time.
  case minimumWidth(BreakpointToken)

  /// Applies the declarations while the generated class is hovered.
  case hover

  /// Applies the declarations while the generated class is focused.
  case focus

  /// Applies the declarations when the user prefers a dark color scheme.
  case dark
}
