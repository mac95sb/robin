/// A font family, size, and weight stored as one typography scale entry.
public struct Typography: Equatable, Sendable {
  /// The CSS font-family value before quoting and escaping.
  public let family: String

  /// The font size emitted in pixels.
  public let size: Int

  /// The numeric CSS font weight.
  public let weight: Int

  /// Creates a typography scale entry.
  ///
  /// - Parameters:
  ///   - family: The font-family name. CSS-significant characters are escaped when emitted.
  ///   - size: The font size in pixels.
  ///   - weight: The numeric CSS font weight.
  public init(family: String, size: Int, weight: Int) {
    self.family = family
    self.size = size
    self.weight = weight
  }
}
