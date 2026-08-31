public enum DataScaleError: Error, Equatable, Sendable { case empty, exhausted }

public struct CategoricalColorScale: Equatable, Sendable {
  public enum Overflow: Equatable, Sendable { case cycle, diagnose }
  public let colors: [Color]
  public let overflow: Overflow

  public init(_ colors: [Color], overflow: Overflow = .diagnose) throws {
    guard !colors.isEmpty else { throw DataScaleError.empty }
    self.colors = colors
    self.overflow = overflow
  }

  public func color(at index: Int) throws -> Color {
    if index < colors.count { return colors[max(index, 0)] }
    guard overflow == .cycle else { throw DataScaleError.exhausted }
    return colors[index % colors.count]
  }
}

public struct ContinuousColorScale: Equatable, Sendable {
  public let stops: [Color]

  public init(_ stops: [Color]) throws {
    guard !stops.isEmpty else { throw DataScaleError.empty }
    self.stops = stops
  }

  public func color(at progress: Double) -> Color {
    guard stops.count > 1 else { return stops[0] }
    let position = min(max(progress, 0), 1) * Double(stops.count - 1)
    let lower = Int(position.rounded(.down))
    let upper = min(lower + 1, stops.count - 1)
    return stops[lower].interpolated(to: stops[upper], progress: position - Double(lower))
  }
}
