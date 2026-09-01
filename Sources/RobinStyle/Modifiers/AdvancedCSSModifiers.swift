import RobinHTML

/// A browser-native CSS containment mode.
public enum ContainerType: String, Sendable {
  case normal
  case inlineSize = "inline-size"
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
  case top, right, bottom, left, center
}

/// A typed scroll or view timeline name.
public struct AnimationTimeline: Equatable, Hashable, Sendable {
  let cssName: String

  public init(_ identifier: String) throws {
    self.cssName = try cssCustomIdentifier(identifier)
  }
}

/// A native transition behavior.
public enum TransitionBehavior: String, Sendable {
  case normal
  case allowDiscrete = "allow-discrete"
}

/// Validation errors for advanced typed CSS values.
public enum AdvancedStyleError: Error, Equatable, Sendable {
  case invalidIdentifier(String)
  case invalidKeyframePercentage(Int)
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
  public func containerType(
    _ type: ContainerType,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.containerType, .keyword(type.rawValue), on: condition)]
    )
  }

  public func anchor(_ anchor: Anchor, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.anchorName, .keyword(anchor.cssName), on: condition)]
    )
  }

  public func position(
    at anchor: Anchor,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.positionAnchor, .keyword(anchor.cssName), on: condition)]
    )
  }

  public func transitionBehavior(
    _ behavior: TransitionBehavior,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.transitionBehavior, .keyword(behavior.rawValue), on: condition)]
    )
  }

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

  public func scrollTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.scrollTimelineName, .keyword(timeline.cssName), on: condition)]
    )
  }

  public func viewTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.viewTimelineName, .keyword(timeline.cssName), on: condition)]
    )
  }

  public func animationTimeline(
    _ timeline: AnimationTimeline,
    on condition: Condition = .always
  ) -> some Component {
    StyledComponent(
      content: self,
      declarations: [styled(.animationTimeline, .keyword(timeline.cssName), on: condition)]
    )
  }

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
