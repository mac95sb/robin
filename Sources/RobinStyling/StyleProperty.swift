/// A CSS property supported by the typed validation compiler.
///
/// Cases are ordered by `rawValue` to keep compiled CSS deterministic.
public enum StyleProperty: String, Comparable, Sendable {
  case backgroundColor = "background-color"
  case borderRadius = "border-radius"
  case color
  case display
  case fontSize = "font-size"
  case gap
  case padding

  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
