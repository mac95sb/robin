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
    /// The intrinsic width in pixels, when known.
    public let width: Int?
    /// The intrinsic height in pixels, when known.
    public let height: Int?
    /// The image MIME type, when known.
    public let mediaType: String?

    /// Creates a social sharing image description.
    ///
    /// - Parameters:
    ///   - url: The absolute URL of the image.
    ///   - alternativeText: Text describing the image for people who cannot see it.
    ///   - width: The positive intrinsic width in pixels, when known.
    ///   - height: The positive intrinsic height in pixels, when known.
    ///   - mediaType: The image MIME type, when known.
    public init(
      url: String,
      alternativeText: String,
      width: Int? = nil,
      height: Int? = nil,
      mediaType: String? = nil
    ) {
      precondition(width.map { $0 > 0 } ?? true)
      precondition(height.map { $0 > 0 } ?? true)
      self.url = url
      self.alternativeText = alternativeText
      self.width = width
      self.height = height
      self.mediaType = mediaType
    }
  }

  /// The document title.
  public var title: String?
  /// The site name appended to a page title.
  public var site: String?
  /// The text placed between a page title and site name.
  public var separator: String?
  /// The document description.
  public var description: String?
  /// The canonical absolute URL.
  public var canonicalURL: String?
  /// The language tag used for the document.
  public var language: String?
  /// The social sharing image.
  public var image: Image?
  /// Typed schema-specific facts emitted as JSON-LD.
  public var structuredData: [StructuredData]

  /// Creates document and sharing metadata.
  ///
  /// Leave a value as `nil` to omit it or, when this value is used as page metadata, inherit the
  /// corresponding application default.
  ///
  /// - Parameters:
  ///   - title: The document title.
  ///   - site: The site name appended to the page title.
  ///   - separator: Text separating the page title and site name. Defaults to `" | "` when needed.
  ///   - description: A concise description of the document.
  ///   - canonicalURL: The preferred absolute URL for the document.
  ///   - language: The document's language tag, such as `en` or `en-GB`.
  ///   - image: The image used when the document is shared.
  ///   - structuredData: Schema-specific facts that supplement the shared metadata.
  public init(
    title: String? = nil,
    site: String? = nil,
    separator: String? = nil,
    description: String? = nil,
    canonicalURL: String? = nil,
    language: String? = nil,
    image: Image? = nil,
    structuredData: [StructuredData] = []
  ) {
    precondition(separator.map { $0.contains(where: { !$0.isWhitespace }) } ?? true)
    self.title = title
    self.site = site
    self.separator = separator
    self.description = description
    self.canonicalURL = canonicalURL
    self.language = language
    self.image = image
    self.structuredData = structuredData
  }

  /// The final document title after applying the site name and separator.
  public var composedTitle: String? {
    switch (title, site) {
    case (.some(let title), .some(let site)): "\(title)\(separator ?? " | ")\(site)"
    case (.some(let title), nil): title
    case (nil, .some(let site)): site
    case (nil, nil): nil
    }
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
      site: page.site ?? site,
      separator: page.separator ?? separator,
      description: page.description ?? description,
      canonicalURL: page.canonicalURL ?? canonicalURL,
      language: page.language ?? language,
      image: page.image ?? image,
      structuredData: page.structuredData.isEmpty ? structuredData : page.structuredData
    )
  }
}
