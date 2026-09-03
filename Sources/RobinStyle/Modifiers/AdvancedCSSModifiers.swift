import RobinHTML

/// A browser-native CSS containment mode.
public enum ContainerType: String, Sendable {
  /// Establishes no size-query container.
  case normal
  /// Allows queries against the inline dimension.
  case inlineSize = "inline-size"
  /// Allows queries against both dimensions.
  case size
}

/// A typed anchor name used by native CSS anchor positioning.
public struct Anchor: Equatable, Hashable, Sendable {
  let cssName: String

  /// Creates an anchor from an ASCII identifier. Robin supplies the required CSS prefix.
  public init(_ identifier: String) throws {
    self.cssName = try cssCustomIdentifier(identifier)
  }
}

/// An edge resolved by CSS's native `anchor()` function.
public enum AnchorEdge: String, Sendable {
  /// The top edge.
  case top
  /// The right edge.
  case right
  /// The bottom edge.
  case bottom
  /// The left edge.
  case left
  /// The center position.
  case center
}

/// A typed scroll or view timeline name.
public struct AnimationTimeline: Equatable, Hashable, Sendable {
  let cssName: String

  /// Creates a timeline from an ASCII identifier.
  ///
  /// - Parameter identifier: The unprefixed timeline identifier.
  /// - Throws: ``AdvancedStyleError/invalidIdentifier(_:)`` for an invalid CSS identifier.
  public init(_ identifier: String) throws {
    self.cssName = try cssCustomIdentifier(identifier)
  }
}

/// A native transition behavior.
public enum TransitionBehavior: String, Sendable {
  /// Uses normal transition interpolation rules.
  case normal
  /// Allows transitions for discrete properties.
  case allowDiscrete = "allow-discrete"
}

/// Validation errors for advanced typed CSS values.
public enum AdvancedStyleError: Error, Equatable, Sendable {
  /// A CSS anchor or timeline identifier is invalid.
  case invalidIdentifier(String)
  /// A keyframe stop lies outside `0...100`.
  case invalidKeyframePercentage(Int)
  /// A keyframe animation contains no stops.
  case emptyAnimation
}

private func cssCustomIdentifier(_ identifier: String) throws -> String {
  let allowed = identifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
  guard allowed, identifier.first?.isLetter == true else {
    throw AdvancedStyleError.invalidIdentifier(identifier)
  }
  return "--r-\(identifier)"
}

extension Component {
  /// Establishes this component as a CSS size-query container.
  ///
  /// - Parameters:
  ///   - type: The dimensions exposed to container queries.
  ///   - condition: The condition under which the declaration applies.
  public func containerType(
    _ type: ContainerType,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.containerType, .keyword(type.rawValue), on: condition)]
    )
  }

  /// Names this component as a native CSS positioning anchor.
  ///
  /// - Parameters:
  ///   - anchor: The typed anchor name.
  ///   - condition: The condition under which the declaration applies.
  public func anchor(_ anchor: Anchor, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.anchorName, .keyword(anchor.cssName), on: condition)]
    )
  }

  /// Selects an anchor as this component's default positioning anchor.
  ///
  /// - Parameters:
  ///   - anchor: The typed anchor name.
  ///   - condition: The condition under which the declaration applies.
  public func position(
    at anchor: Anchor,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.positionAnchor, .keyword(anchor.cssName), on: condition)]
    )
  }

  /// Configures whether discrete CSS properties may transition.
  ///
  /// - Parameters:
  ///   - behavior: The native transition behavior.
  ///   - condition: The condition under which the declaration applies.
  public func transitionBehavior(
    _ behavior: TransitionBehavior,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.transitionBehavior, .keyword(behavior.rawValue), on: condition)]
    )
  }

  /// Positions this component's top edge relative to an anchor edge.
  ///
  /// - Parameters:
  ///   - anchor: The typed positioning anchor.
  ///   - edge: The anchor edge used as the position.
  ///   - condition: The condition under which the declaration applies.
  public func anchoredTop(
    to anchor: Anchor,
    edge: AnchorEdge = .bottom,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [
        styled(.top, .keyword("anchor(\(anchor.cssName) \(edge.rawValue))"), on: condition)
      ]
    )
  }

  /// Names the component's scroll progress timeline.
  ///
  /// - Parameters:
  ///   - timeline: The typed timeline name.
  ///   - condition: The condition under which the declaration applies.
  public func scrollTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.scrollTimelineName, .keyword(timeline.cssName), on: condition)]
    )
  }

  /// Names the component's view progress timeline.
  ///
  /// - Parameters:
  ///   - timeline: The typed timeline name.
  ///   - condition: The condition under which the declaration applies.
  public func viewTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.viewTimelineName, .keyword(timeline.cssName), on: condition)]
    )
  }

  /// Selects a scroll or view timeline for this component's animation.
  ///
  /// - Parameters:
  ///   - timeline: The typed timeline name.
  ///   - condition: The condition under which the declaration applies.
  public func animationTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.animationTimeline, .keyword(timeline.cssName), on: condition)]
    )
  }

  /// Applies a deterministic keyframe animation.
  ///
  /// - Parameters:
  ///   - animation: The keyframes to apply.
  ///   - durationMilliseconds: The nonnegative animation duration.
  ///   - condition: The condition under which the declarations apply.
  public func animation(
    _ animation: KeyframeAnimation,
    durationMilliseconds: Int,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [
        styled(.animationName, .keyword(animation.name), on: condition),
        styled(.animationDuration, .keyword("\(max(durationMilliseconds, 0))ms"), on: condition),
      ]
    )
  }
}
