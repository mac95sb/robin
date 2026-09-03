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
