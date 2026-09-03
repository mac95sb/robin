/// Validation errors for advanced typed CSS values.
public enum AdvancedStyleError: Error, Equatable, Sendable {
  /// A CSS anchor or timeline identifier is invalid.
  case invalidIdentifier(String)
  /// A keyframe stop lies outside `0...100`.
  case invalidKeyframePercentage(Int)
  /// A keyframe animation contains no stops.
  case emptyAnimation
}
