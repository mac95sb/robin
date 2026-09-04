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
