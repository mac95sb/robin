/// A single image.
///
/// `Image` lowers to a void `<img src alt>` element and never accepts children.
public struct Image: Component {
  private let source: String
  private let alternateText: String
  private let identifier: String?

  /// Creates an image.
  ///
  /// - Parameters:
  ///   - source: The image's source, serialized as `src`.
  ///   - alternateText: A textual alternative describing the image, serialized as `alt`.
  ///   - id: An optional document-wide element identifier.
  public init(source: String, alternateText: String, id: String? = nil) {
    self.source = source
    self.alternateText = alternateText
    self.identifier = id
  }

  /// The resolved image element.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.source(source), .alternateText(alternateText)]
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(.element(.init(kind: .img, attributes: attributes)))
  }
}
