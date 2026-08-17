/// A typed external embed, such as a video or social post, referenced by URL.
///
/// Embeds render as sandboxed `<iframe>` elements (see ``HTMLRenderer``) and are
/// validated by ``RenderValidator``, which requires an `https://` origin. Content
/// pipelines may additionally restrict embeds to an allowlist of hostnames (see
/// `MarkdownContentParser` in the RobinContent module).
public struct EmbedNode: Equatable, Sendable {
  /// The embed URL. Renderers require an `https://` origin.
  public let source: String

  /// A human-readable title used as the iframe's accessible name.
  public let title: String

  /// Creates an embed node.
  ///
  /// - Parameters:
  ///   - source: The embed URL, expected to use an `https://` origin.
  ///   - title: The embed's accessible title.
  public init(source: String, title: String) {
    self.source = source
    self.title = title
  }
}
