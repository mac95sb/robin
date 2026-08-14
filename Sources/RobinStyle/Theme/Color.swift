/// A color represented in Robin's canonical OKLCH color space.
///
/// Components are normalized at initialization so downstream contrast,
/// interpolation, and CSS serialization operate on canonical values.
public struct Color: Equatable, Hashable, Sendable {
  /// Perceptual lightness in the closed range `0...1`.
  public let lightness: Double

  /// Chroma expressed as a nonnegative value.
  public let chroma: Double

  /// Hue normalized to the range `0..<360` degrees.
  public let hue: Double

  /// Opacity in the closed range `0...1`.
  public let alpha: Double

  /// Creates an OKLCH color and normalizes its components.
  ///
  /// Finite lightness and alpha values are clamped to `0...1`, finite chroma is
  /// clamped to zero or greater, and finite hue wraps into `0..<360` degrees.
  /// Non-finite components normalize deterministically to `0`, except alpha,
  /// which normalizes to `1`.
  ///
  /// - Parameters:
  ///   - lightness: The perceptual lightness component.
  ///   - chroma: The chroma component.
  ///   - hue: The hue angle in degrees; values outside one turn are wrapped.
  ///   - alpha: The opacity component. The default is fully opaque.
  public init(lightness: Double, chroma: Double, hue: Double, alpha: Double = 1) {
    self.lightness = lightness.isFinite ? min(max(lightness, 0), 1) : 0
    self.chroma = chroma.isFinite ? max(chroma, 0) : 0
    if hue.isFinite {
      let remainder = hue.truncatingRemainder(dividingBy: 360)
      self.hue = remainder >= 0 ? remainder : remainder + 360
    } else {
      self.hue = 0
    }
    self.alpha = alpha.isFinite ? min(max(alpha, 0), 1) : 1
  }
}
