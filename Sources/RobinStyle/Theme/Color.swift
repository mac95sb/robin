import Foundation

/// A color represented in Robin's canonical OKLCH color space.
///
/// Components are normalized at initialization so downstream contrast,
/// interpolation, and CSS serialization operate on canonical values.
public struct Color: Equatable, Hashable, Sendable {
  /// An invalid textual color representation.
  public enum ParseError: Error, Equatable, Sendable {
    /// The supplied string is not a supported hexadecimal color.
    case invalidHex(String)
  }
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

  /// Creates an OKLCH color with positional component arguments.
  ///
  /// - Parameters:
  ///   - lightness: Perceptual lightness.
  ///   - chroma: Chroma intensity.
  ///   - hue: The hue angle in degrees.
  ///   - alpha: Opacity, defaulting to fully opaque.
  public static func oklch(_ lightness: Double, _ chroma: Double, _ hue: Double, alpha: Double = 1)
    -> Self
  {
    Self(lightness: lightness, chroma: chroma, hue: hue, alpha: alpha)
  }

  /// Parses `#RGB`, `#RGBA`, `#RRGGBB`, or `#RRGGBBAA` and converts sRGB to canonical OKLCH.
  public init(hex: String) throws {
    let source = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let expanded: String
    switch source.count {
    case 3, 4: expanded = source.map { "\($0)\($0)" }.joined()
    case 6, 8: expanded = source
    default: throw ParseError.invalidHex(hex)
    }
    guard let raw = UInt64(expanded, radix: 16) else { throw ParseError.invalidHex(hex) }
    let hasAlpha = expanded.count == 8
    let red = Double((raw >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
    let green = Double((raw >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
    let blue = Double((raw >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
    let alpha = hasAlpha ? Double(raw & 0xFF) / 255 : 1
    self = Self.sRGB(red: red, green: green, blue: blue, alpha: alpha)
  }

  /// WCAG contrast ratio after deterministic OKLCH-to-sRGB gamut clipping.
  public func contrastRatio(with other: Self) -> Double {
    let first = relativeLuminance
    let second = other.relativeLuminance
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
  }

  /// Interpolates toward another color along the shortest hue path.
  ///
  /// - Parameters:
  ///   - other: The destination color.
  ///   - progress: Interpolation progress clamped to `0...1`.
  /// - Returns: The interpolated canonical color.
  public func interpolated(to other: Self, progress: Double) -> Self {
    let amount = min(max(progress, 0), 1)
    let rawHueDelta = (other.hue - hue).truncatingRemainder(dividingBy: 360)
    let hueDelta =
      rawHueDelta > 180 ? rawHueDelta - 360 : (rawHueDelta < -180 ? rawHueDelta + 360 : rawHueDelta)
    return Self(
      lightness: lightness + (other.lightness - lightness) * amount,
      chroma: chroma + (other.chroma - chroma) * amount,
      hue: hue + hueDelta * amount,
      alpha: alpha + (other.alpha - alpha) * amount
    )
  }

  private static func sRGB(red: Double, green: Double, blue: Double, alpha: Double) -> Self {
    func linear(_ value: Double) -> Double {
      value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    let r = linear(red)
    let g = linear(green)
    let b = linear(blue)
    let l = 0.412_221_470_8 * r + 0.536_332_536_3 * g + 0.051_445_992_9 * b
    let m = 0.211_903_498_2 * r + 0.680_699_545_1 * g + 0.107_396_956_6 * b
    let s = 0.088_302_461_9 * r + 0.281_718_837_6 * g + 0.629_978_700_5 * b
    let lRoot = cbrt(l)
    let mRoot = cbrt(m)
    let sRoot = cbrt(s)
    let lightness = 0.210_454_255_3 * lRoot + 0.793_617_785 * mRoot - 0.004_072_046_8 * sRoot
    let a = 1.977_998_495_1 * lRoot - 2.428_592_205 * mRoot + 0.450_593_709_9 * sRoot
    let bValue = 0.025_904_037_1 * lRoot + 0.782_771_766_2 * mRoot - 0.808_675_766 * sRoot
    return Self(
      lightness: lightness,
      chroma: hypot(a, bValue),
      hue: atan2(bValue, a) * 180 / .pi,
      alpha: alpha
    )
  }

  private var relativeLuminance: Double {
    let radians = hue * .pi / 180
    let a = chroma * cos(radians)
    let b = chroma * sin(radians)
    let lRoot = lightness + 0.396_337_777_4 * a + 0.215_803_757_3 * b
    let mRoot = lightness - 0.105_561_345_8 * a - 0.063_854_172_8 * b
    let sRoot = lightness - 0.089_484_177_5 * a - 1.291_485_548 * b
    let l = lRoot * lRoot * lRoot
    let m = mRoot * mRoot * mRoot
    let s = sRoot * sRoot * sRoot
    let red = min(max(4.076_741_662_1 * l - 3.307_711_591_3 * m + 0.230_969_929_2 * s, 0), 1)
    let green = min(max(-1.268_438_004_6 * l + 2.609_757_401_1 * m - 0.341_319_396_5 * s, 0), 1)
    let blue = min(max(-0.004_196_086_3 * l - 0.703_418_614_7 * m + 1.707_614_701 * s, 0), 1)
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue
  }
}
