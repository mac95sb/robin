/// Document and sharing metadata associated with an application or page.
///
/// Application metadata supplies defaults that a page can selectively replace using
/// ``merging(page:)``.
public struct Metadata: Equatable, Sendable {
  /// A social sharing image description.
  public struct Image: Equatable, Sendable {
    /// The absolute image URL.
    public let url: String
    /// Accessible alternative text for the image.
    public let alternativeText: String

    /// Creates a social sharing image description.
    ///
    /// - Parameters:
    ///   - url: The absolute URL of the image.
    ///   - alternativeText: Text describing the image for people who cannot see it.
    public init(url: String, alternativeText: String) {
      self.url = url
      self.alternativeText = alternativeText
    }
  }

  /// The document title.
  public var title: String?
  /// The document description.
  public var description: String?
  /// The canonical absolute URL.
  public var canonicalURL: String?
  /// The language tag used for the document.
  public var language: String?
  /// The social sharing image.
  public var image: Image?

  /// Creates document and sharing metadata.
  ///
  /// Leave a value as `nil` to omit it or, when this value is used as page metadata, inherit the
  /// corresponding application default.
  ///
  /// - Parameters:
  ///   - title: The document title.
  ///   - description: A concise description of the document.
  ///   - canonicalURL: The preferred absolute URL for the document.
  ///   - language: The document's language tag, such as `en` or `en-GB`.
  ///   - image: The image used when the document is shared.
  public init(
    title: String? = nil,
    description: String? = nil,
    canonicalURL: String? = nil,
    language: String? = nil,
    image: Image? = nil
  ) {
    self.title = title
    self.description = description
    self.canonicalURL = canonicalURL
    self.language = language
    self.image = image
  }

  /// Returns page metadata overlaid on application defaults.
  ///
  /// Each non-`nil` page value replaces its application-level counterpart. A `nil` page value
  /// preserves the value from this metadata.
  ///
  /// - Parameter page: The page-specific metadata to overlay on this value.
  /// - Returns: The merged metadata without modifying either input.
  public func merging(page: Metadata) -> Metadata {
    Metadata(
      title: page.title ?? title,
      description: page.description ?? description,
      canonicalURL: page.canonicalURL ?? canonicalURL,
      language: page.language ?? language,
      image: page.image ?? image
    )
  }
}
