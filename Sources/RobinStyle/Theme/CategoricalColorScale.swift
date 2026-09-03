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
