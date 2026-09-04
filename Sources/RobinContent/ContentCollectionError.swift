/// Content collection query failures.
public enum ContentCollectionError: Error, Equatable, Sendable {
  /// The page number or size was nonpositive or outside the collection.
  case invalidPage
}
