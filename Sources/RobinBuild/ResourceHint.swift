/// A browser resource hint derived from typed build metadata.
public enum ResourceHint: Equatable, Sendable {
  /// Fetch an artifact early for its declared destination.
  case preload(as: Destination)
  /// Establish an early connection to an origin.
  case preconnect(origin: String)

  /// The fetch destination for a preloaded artifact.
  public enum Destination: String, Equatable, Sendable {
    /// A stylesheet.
    case style
    /// A JavaScript module or script.
    case script
    /// An image.
    case image
    /// A font.
    case font
    /// A fetch request without a narrower destination.
    case fetch
  }
}
