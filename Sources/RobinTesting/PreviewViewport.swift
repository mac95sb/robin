/// A viewport offered by a preview dashboard.
public struct PreviewViewport: Equatable, Sendable {
  /// The viewport's display name.
  public let name: String
  /// The width in CSS pixels.
  public let width: Int
  /// The height in CSS pixels.
  public let height: Int

  /// Creates a preview viewport.
  ///
  /// - Parameters:
  ///   - name: A nonempty display name.
  ///   - width: A positive width in CSS pixels.
  ///   - height: A positive height in CSS pixels.
  public init(_ name: String, width: Int, height: Int) {
    precondition(name.contains { !$0.isWhitespace } && width > 0 && height > 0)
    self.name = name
    self.width = width
    self.height = height
  }
}
