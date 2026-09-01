/// A deterministic typed keyframe animation.
public struct KeyframeAnimation: Equatable, Sendable {
  /// One percentage position in a keyframe animation.
  public struct Stop: Equatable, Sendable {
    /// A typed transform applied at an animation stop.
    public enum Transform: Equatable, Sendable {
      /// Scales the element uniformly by the supplied factor.
      case scale(Double)
      /// Translates the element by pixel offsets.
      case translate(x: Int, y: Int)

      var css: String {
        switch self {
        case .scale(let value): "scale(\(CSSSerialization.decimal(value)))"
        case .translate(let x, let y): "translate(\(x)px,\(y)px)"
        }
      }

    }

    /// The stop position in the closed range `0...100`.
    public let percentage: Int
    /// An optional opacity clamped to `0...1`.
    public let opacity: Double?
    /// An optional typed transform.
    public let transform: Transform?

    /// Creates an animation stop.
    ///
    /// - Parameters:
    ///   - percentage: The stop position in the closed range `0...100`.
    ///   - opacity: An optional opacity value, clamped to `0...1`.
    ///   - transform: An optional typed transform.
    /// - Throws: ``AdvancedStyleError/invalidKeyframePercentage(_:)`` for an out-of-range stop.
    public init(
      _ percentage: Int,
      opacity: Double? = nil,
      transform: Transform? = nil
    ) throws {
      guard (0...100).contains(percentage) else {
        throw AdvancedStyleError.invalidKeyframePercentage(percentage)
      }
      self.percentage = percentage
      self.opacity = opacity.map { min(max($0, 0), 1) }
      self.transform = transform
    }

    var css: String {
      var declarations: [String] = []
      if let opacity {
        declarations.append("opacity:\(CSSSerialization.decimal(opacity))")
      }
      if let transform { declarations.append("transform:\(transform.css)") }
      return "\(percentage)%{\(declarations.joined(separator: ";"))}"
    }
  }

  /// Stops sorted by percentage.
  public let stops: [Stop]
  /// The deterministic generated CSS animation name.
  public let name: String

  /// Creates a deterministic keyframe animation.
  ///
  /// - Parameter stops: One or more animation stops.
  /// - Throws: ``AdvancedStyleError/emptyAnimation`` when `stops` is empty.
  public init(stops: [Stop]) throws {
    guard !stops.isEmpty else { throw AdvancedStyleError.emptyAnimation }
    self.stops = stops.sorted { $0.percentage < $1.percentage }
    self.name = "r-kf-\(CSSSerialization.stableHash(self.stops.map(\.css).joined()))"
  }

  var css: String { "@keyframes \(name){\(stops.map(\.css).joined())}" }

}

/// Whether to emit native cross-document View Transition CSS.
public enum ViewTransitionNavigation: Equatable, Sendable {
  /// Emits no cross-document view-transition CSS.
  case disabled
  /// Emits native cross-document view-transition CSS.
  case enabled
}
