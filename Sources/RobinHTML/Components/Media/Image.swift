/// A single image.
///
/// `Image` lowers to a void `<img src alt>` element and never accepts children.
public struct Image: Component {
  /// One responsive image source and its intrinsic pixel width.
  public struct Source: Equatable, Sendable {
    /// The image source reference.
    public let source: String
    /// The source width in pixels.
    public let width: Int

    /// Creates a responsive image source.
    ///
    /// - Parameters:
    ///   - source: The image source reference.
    ///   - width: The positive intrinsic width in pixels.
    public init(_ source: String, width: Int) {
      self.source = source
      self.width = width
    }
  }

  private let source: String
  private let alternateText: String
  private let variants: [Source]
  private let sizes: String?
  private let identifier: String?

  /// Creates an image.
  ///
  /// - Parameters:
  ///   - source: The image's source, serialized as `src`.
  ///   - alternateText: A textual alternative describing the image, serialized as `alt`.
  ///   - variants: Responsive source candidates for `srcset`.
  ///   - sizes: The responsive slot-size expression.
  ///   - id: An optional document-wide element identifier.
  public init(
    source: String,
    alternateText: String,
    variants: [Source] = [],
    sizes: String? = nil,
    id: String? = nil
  ) {
    self.source = source
    self.alternateText = alternateText
    self.variants = variants
    self.sizes = sizes
    self.identifier = id
  }

  /// The resolved image element.
  public var body: ComponentContent {
    var attributes: [RenderElement.Attribute] = [.source(source), .alternateText(alternateText)]
    if !variants.isEmpty {
      attributes.append(
        .sourceSet(variants.map { .init(source: $0.source, width: $0.width) }))
    }
    if let sizes { attributes.append(.sizes(sizes)) }
    if let identifier { attributes.append(.identifier(identifier)) }
    return .node(.element(.init(kind: .img, attributes: attributes)))
  }
}
