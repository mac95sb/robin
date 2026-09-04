/// A destination found in a Markdown document.
public enum ContentReference: Equatable, Sendable {
  /// A link to another page or an external resource.
  case link(String)
  /// An image or other local content asset.
  case asset(String)
}
