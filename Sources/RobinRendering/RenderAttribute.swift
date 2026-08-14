/// A name-value HTML attribute on an ``ElementNode``.
///
/// The value is HTML-escaped by ``HTMLRenderer`` when emitted, so it never needs
/// pre-escaping.
public struct RenderAttribute: Equatable, Sendable {
  /// The attribute name, for example `id` or `data-section`.
  public let name: String

  /// The attribute value, HTML-escaped at render time.
  public let value: String

  /// Creates a render attribute.
  ///
  /// - Parameters:
  ///   - name: The attribute name.
  ///   - value: The attribute value.
  public init(_ name: String, _ value: String) {
    self.name = name
    self.value = value
  }
}
