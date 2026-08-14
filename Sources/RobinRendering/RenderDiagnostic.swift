/// A structural problem in a render tree, reported by ``RenderValidator``.
///
/// Diagnostics are nonfatal: validation returns the complete list rather than
/// throwing on the first problem, so tooling can surface every issue at once.
public enum RenderDiagnostic: Equatable, Error, Sendable {
  /// An element declares the same attribute more than once.
  case duplicateAttribute(element: ElementName, name: String)

  /// An interactive element (`button` or `input`) is nested inside a `button`,
  /// which is invalid HTML and breaks assistive technology.
  case interactiveElementNestedInButton

  /// An embed uses a non-`https://` origin.
  case invalidEmbedOrigin(String)
}
