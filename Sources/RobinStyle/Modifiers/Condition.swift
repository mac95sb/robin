/// A CSS-cascade condition applied to a grouped style modifier.
///
/// Conditions are compiled into selectors or media queries and do not require
/// client-side runtime state.
public indirect enum Condition: Equatable, Hashable, Sendable {
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
  /// Applies below a tokenized viewport width.
  case below(BreakpointToken)
  /// Applies between two tokenized viewport widths.
  case between(BreakpointToken, BreakpointToken)
  /// Applies while a checkable control is checked.
  case checked
  /// Applies while a disclosure or dialog is open.
  case open
  /// Applies when the element contains a descendant matching the selector.
  case has(String)
  /// Applies at or above a tokenized container width.
  case containerMinimumWidth(BreakpointToken)
  /// Applies through the native CSS starting-style rule.
  case startingStyle
  /// Applies when both nested conditions match.
  case and(Condition, Condition)
  /// Applies when either nested condition matches.
  case or(Condition, Condition)
  /// Applies when the nested condition does not match.
  case not(Condition)

  /// Applies at or above the small breakpoint.
  public static let sm = minimumWidth(.sm)
  /// Applies at or above the medium breakpoint.
  public static let md = minimumWidth(.md)
  /// Applies at or above the large breakpoint.
  public static let lg = minimumWidth(.lg)
  /// Applies at or above the extra-large breakpoint.
  public static let xl = minimumWidth(.xl)
  /// Applies at or above the double-extra-large breakpoint.
  public static let xxl = minimumWidth(.xxl)
}

/// Combines two conditions that must both match.
public func && (lhs: Condition, rhs: Condition) -> Condition { .and(lhs, rhs) }
/// Combines two conditions when either may match.
public func || (lhs: Condition, rhs: Condition) -> Condition { .or(lhs, rhs) }
/// Negates a style condition.
prefix public func ! (condition: Condition) -> Condition { .not(condition) }
