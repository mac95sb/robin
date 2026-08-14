/// A color, blur radius, and offset stored as one shadow scale entry.
public struct Shadow: Equatable, Sendable {
  /// The shadow color in canonical OKLCH space.
  public let color: Color

  /// The shadow blur radius in pixels.
  public let radius: Int

  /// The horizontal shadow offset in pixels.
  public let x: Int

  /// The vertical shadow offset in pixels.
  public let y: Int

  /// Creates a shadow scale entry.
  ///
  /// - Parameters:
  ///   - color: The shadow color.
  ///   - radius: The blur radius in pixels.
  ///   - x: The horizontal offset in pixels. The default is `0`.
  ///   - y: The vertical offset in pixels. The default is `0`.
  public init(color: Color, radius: Int, x: Int = 0, y: Int = 0) {
    self.color = color
    self.radius = radius
    self.x = x
    self.y = y
  }
}
