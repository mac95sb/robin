/// A single stop within a ``KeyframeAnimation``.
public struct Keyframe: Equatable, Sendable {
  /// The stop's position as a percentage of the animation's duration, in `0...100`.
  public let percentage: Int

  /// The declarations applied at this stop.
  public let declarations: [StyleDeclaration]

  /// Creates a keyframe stop.
  ///
  /// - Parameters:
  ///   - percentage: The stop's position as a percentage in `0...100`.
  ///   - declarations: The declarations applied at this stop.
  public init(percentage: Int, declarations: [StyleDeclaration]) {
    self.percentage = percentage
    self.declarations = declarations
  }
}

/// A typed, named CSS animation compiled to an `@keyframes` rule.
public struct KeyframeAnimation: Equatable, Sendable {
  /// The animation's name, referenced by the `animation-name` property.
  public let name: String

  /// The animation's stops, in any order; the compiler sorts them by percentage.
  public let stops: [Keyframe]

  /// Creates a typed keyframe animation.
  ///
  /// - Parameters:
  ///   - name: The animation's name.
  ///   - stops: The animation's stops.
  public init(name: String, stops: [Keyframe]) {
    self.name = name
    self.stops = stops
  }
}
