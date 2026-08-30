/// A CSS property supported by the typed validation compiler.
///
/// Cases are ordered by `rawValue` to keep compiled CSS deterministic.
public enum StyleProperty: String, Comparable, Sendable {
  case anchorName = "anchor-name"
  case animationTimeline = "animation-timeline"
  case backgroundColor = "background-color"
  case borderRadius = "border-radius"
  case color
  case contentVisibility = "content-visibility"
  case display
  case fontSize = "font-size"
  case gap
  case padding
  case positionAnchor = "position-anchor"
  case scrollTimelineName = "scroll-timeline-name"
  case transitionBehavior = "transition-behavior"
  case viewTimelineName = "view-timeline-name"

  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
