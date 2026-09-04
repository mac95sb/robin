import Foundation

/// Document and sharing metadata associated with an application or page.
///
/// Application metadata supplies defaults that a page can selectively replace using
/// ``merging(page:)``.
public struct Metadata: Equatable, Sendable {
  /// The Open Graph object represented by a page.
  public enum OpenGraphType: String, Equatable, Sendable {
    /// A general website page.
    case website
    /// An article or post.
    case article
  }

  /// The presentation selected for an X card.
  public enum XCardType: String, Equatable, Sendable {
    /// A compact card.
    case summary
    /// A card led by a large image.
    case summaryLargeImage = "summary_large_image"
  }

  /// A person or organization projected into applicable metadata targets.
  public struct Identity: Equatable, Sendable {
    /// Display name.
    public let name: String
    /// Absolute profile or publisher URL.
    public let url: String?

    /// Creates a metadata identity.
    public init(_ name: String, url: String? = nil) {
      precondition(!name.isEmpty)
      self.name = name
      self.url = url
    }
  }

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

  /// Optional social-card fields that override shared metadata.
  public struct Social: Equatable, Sendable {
    /// Social title override.
    public let title: String?
    /// Social description override.
    public let description: String?
    /// Social image override.
    public let image: Image?

    /// Creates a partial social-card override.
    public init(title: String? = nil, description: String? = nil, image: Image? = nil) {
      self.title = title
      self.description = description
      self.image = image
    }

    fileprivate func merging(_ page: Self?) -> Self {
      Self(
        title: page?.title ?? title,
        description: page?.description ?? description,
        image: page?.image ?? image)
    }
  }

  /// Search crawler directives.
  public struct Robots: Equatable, Sendable {
    /// Omits the robots metadata tag.
    public static let omitted = Self(index: false, follow: false, isOmitted: true)

    /// Whether crawlers may index the page.
    public let index: Bool
    /// Whether crawlers may follow links.
    public let follow: Bool
    private let isOmitted: Bool

    /// Creates crawler directives.
    public init(index: Bool = true, follow: Bool = true) {
      self.index = index
      self.follow = follow
      self.isOmitted = false
    }

    private init(index: Bool, follow: Bool, isOmitted: Bool) {
      self.index = index
      self.follow = follow
      self.isOmitted = isOmitted
    }

    package var content: String? {
      isOmitted ? nil : "\(index ? "index" : "noindex"),\(follow ? "follow" : "nofollow")"
    }
  }

  /// A localized equivalent of the current page.
  public struct AlternateLanguage: Equatable, Sendable {
    /// BCP 47 language tag.
    public let language: String
    /// Locale-specific canonical URL.
    public let url: String

    /// Creates an alternate-language link.
    public init(_ language: String, url: String) {
      precondition(!language.isEmpty && !url.isEmpty)
      self.language = language
      self.url = url
    }
  }

  /// A site icon link.
  public struct Icon: Equatable, Sendable {
    /// Icon URL.
    public let url: String
    /// Optional sizes value, such as `32x32` or `any`.
    public let sizes: String?
    /// Optional media type.
    public let mediaType: String?

    /// Creates an icon link.
    public init(url: String, sizes: String? = nil, mediaType: String? = nil) {
      precondition(!url.isEmpty)
      self.url = url
      self.sizes = sizes
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
  /// Page author inherited by social and structured-data projections.
  public var author: Identity?
  /// Site publisher inherited by structured-data projections.
  public var publisher: Identity?
  /// Publication time.
  public var publishedAt: Date?
  /// Last modification time.
  public var modifiedAt: Date?
  /// Open Graph overrides; omitted fields inherit shared metadata.
  public var openGraph: Social?
  /// Open Graph object type; inferred from structured data when omitted.
  public var openGraphType: OpenGraphType?
  /// X card overrides; omitted fields inherit shared metadata.
  public var xCard: Social?
  /// X card presentation; defaults to ``XCardType/summaryLargeImage`` when omitted.
  public var xCardType: XCardType?
  /// Search crawler directives; defaults to indexing and following links.
  public var robots: Robots?
  /// Localized versions of this page.
  public var alternateLanguages: [AlternateLanguage]
  /// Site icon links.
  public var icons: [Icon]
  /// Web application manifest URL.
  public var manifestURL: String?
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
  ///   - author: The page author.
  ///   - publisher: The site publisher.
  ///   - publishedAt: The original publication time.
  ///   - modifiedAt: The most recent modification time.
  ///   - openGraph: Partial Open Graph field overrides.
  ///   - openGraphType: Open Graph object type; inferred when omitted.
  ///   - xCard: Partial X card field overrides.
  ///   - xCardType: X card presentation; defaults to ``XCardType/summaryLargeImage`` when omitted.
  ///   - robots: Search crawler directives. Omit the tag with ``Robots/omitted``.
  ///   - alternateLanguages: Locale-specific versions of the page.
  ///   - icons: Site icon links.
  ///   - manifestURL: The web application manifest URL.
  ///   - structuredData: Schema-specific facts that supplement the shared metadata.
  public init(
    title: String? = nil,
    site: String? = nil,
    separator: String? = nil,
    description: String? = nil,
    canonicalURL: String? = nil,
    language: String? = nil,
    image: Image? = nil,
    author: Identity? = nil,
    publisher: Identity? = nil,
    publishedAt: Date? = nil,
    modifiedAt: Date? = nil,
    openGraph: Social? = nil,
    openGraphType: OpenGraphType? = nil,
    xCard: Social? = nil,
    xCardType: XCardType? = nil,
    robots: Robots? = nil,
    alternateLanguages: [AlternateLanguage] = [],
    icons: [Icon] = [],
    manifestURL: String? = nil,
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
    self.author = author
    self.publisher = publisher
    self.publishedAt = publishedAt
    self.modifiedAt = modifiedAt
    self.openGraph = openGraph
    self.openGraphType = openGraphType
    self.xCard = xCard
    self.xCardType = xCardType
    self.robots = robots
    self.alternateLanguages = alternateLanguages
    self.icons = icons
    self.manifestURL = manifestURL
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
      author: page.author ?? author,
      publisher: page.publisher ?? publisher,
      publishedAt: page.publishedAt ?? publishedAt,
      modifiedAt: page.modifiedAt ?? modifiedAt,
      openGraph: openGraph.map { $0.merging(page.openGraph) } ?? page.openGraph,
      openGraphType: page.openGraphType ?? openGraphType,
      xCard: xCard.map { $0.merging(page.xCard) } ?? page.xCard,
      xCardType: page.xCardType ?? xCardType,
      robots: page.robots ?? robots,
      alternateLanguages: page.alternateLanguages.isEmpty
        ? alternateLanguages : page.alternateLanguages,
      icons: page.icons.isEmpty ? icons : page.icons,
      manifestURL: page.manifestURL ?? manifestURL,
      structuredData: page.structuredData.isEmpty ? structuredData : page.structuredData
    )
  }
}
