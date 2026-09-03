/// The semantic kind of an admonition callout.
///
/// The kind maps to a semantic CSS class (`admonition-<kind>`) at render time,
/// letting a design system style notes, warnings, and tips differently.
public enum AdmonitionKind: String, Equatable, Sendable, CaseIterable {
  /// Supplementary, non-urgent information.
  case note

  /// Helpful, optional guidance.
  case tip

  /// Something that could go wrong if ignored.
  case warning

  /// Critical information that must not be skipped.
  case important
}

/// A callout block that highlights supporting content.
///
/// Admonitions are authored in Markdown through the `Admonition` block
/// directive; see `MarkdownContentParser`.
public struct AdmonitionNode: Equatable, Sendable {
  /// The semantic kind of the callout.
  public let kind: AdmonitionKind

  /// A short heading for the callout.
  public let title: String

  /// The callout's body text.
  public let body: String

  /// Creates an admonition node.
  ///
  /// - Parameters:
  ///   - kind: The semantic kind of the callout.
  ///   - title: A short heading for the callout.
  ///   - body: The callout's body text.
  public init(kind: AdmonitionKind, title: String, body: String) {
    self.kind = kind
    self.title = title
    self.body = body
  }
}

/// A typed block-level node parsed from a content document.
public enum ContentNode: Equatable, Sendable {
  /// A section heading with its outline level (1–6).
  case heading(level: Int, text: String)

  /// A paragraph of body text.
  case paragraph(String)

  /// A fenced code block with an optional language tag.
  case code(language: String?, source: String)

  /// A table: the first row is the header, the rest are body rows.
  case table([[String]])

  /// A footnote definition, referenced by `id` from body text.
  case footnote(id: String, text: String)

  /// A highlighted callout (note, tip, warning, or important).
  case admonition(AdmonitionNode)

  /// A typed external embed.
  case embed(source: String, title: String)
}
