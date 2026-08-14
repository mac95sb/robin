public enum RenderDiagnostic: Equatable, Error, Sendable {
  case duplicateAttribute(element: ElementName, name: String)
  case interactiveElementNestedInButton
  case invalidEmbedOrigin(String)
}
