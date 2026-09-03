/// An invalid or exhausted data-color scale.
public enum DataScaleError: Error, Equatable, Sendable {
  /// The scale contains no colors.
  case empty
  /// A noncycling categorical scale has no color for the requested index.
  case exhausted
}

/// A discrete sequence of colors for categorical data.
public struct CategoricalColorScale: Equatable, Sendable {
  /// The behavior after every configured color has been used.
  public enum Overflow: Equatable, Sendable {
    /// Reuses colors from the start of the scale.
    case cycle
    /// Reports exhaustion instead of reusing a color.
    case diagnose
  }
  /// The nonempty categorical palette.
  public let colors: [Color]
  /// The behavior when an index exceeds the palette.
  public let overflow: Overflow

  /// Creates a categorical color scale.
  ///
  /// - Parameters:
  ///   - colors: The nonempty categorical palette.
  ///   - overflow: The behavior after every color has been used.
  /// - Throws: ``DataScaleError/empty`` when `colors` is empty.
  public init(_ colors: [Color], overflow: Overflow = .diagnose) throws {
    guard !colors.isEmpty else { throw DataScaleError.empty }
    self.colors = colors
    self.overflow = overflow
  }

  /// Resolves a color for a category index.
  ///
  /// - Parameter index: The zero-based category index; negative values select the first color.
  /// - Returns: The selected or cycled color.
  /// - Throws: ``DataScaleError/exhausted`` when a noncycling scale is exhausted.
  public func color(at index: Int) throws -> Color {
    if index < colors.count { return colors[max(index, 0)] }
    guard overflow == .cycle else { throw DataScaleError.exhausted }
    return colors[index % colors.count]
  }
}

/// A continuous gradient interpolated across color stops.
public struct ContinuousColorScale: Equatable, Sendable {
  /// The nonempty ordered gradient stops.
  public let stops: [Color]

  /// Creates a continuous color scale.
  ///
  /// - Parameter stops: The nonempty ordered gradient stops.
  /// - Throws: ``DataScaleError/empty`` when `stops` is empty.
  public init(_ stops: [Color]) throws {
    guard !stops.isEmpty else { throw DataScaleError.empty }
    self.stops = stops
  }

  /// Interpolates a color at normalized progress.
  ///
  /// - Parameter progress: Progress clamped to `0...1`.
  /// - Returns: The interpolated color.
  public func color(at progress: Double) -> Color {
    guard stops.count > 1 else { return stops[0] }
    let position = min(max(progress, 0), 1) * Double(stops.count - 1)
    let lower = Int(position.rounded(.down))
    let upper = min(lower + 1, stops.count - 1)
    return stops[lower].interpolated(to: stops[upper], progress: position - Double(lower))
  }
}
