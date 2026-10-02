/// An empty page registration.
///
/// The default for an ``App`` that registers no pages.
public struct EmptyPages: Pages {
  /// No registered pages.
  public let pages: [any Page] = []

  /// Creates an empty page registration.
  public init() {}
}
