/// An invalid or exhausted data-color scale.
public enum DataScaleError: Error, Equatable, Sendable {
  /// The scale contains no colors.
  case empty
  /// A noncycling categorical scale has no color for the requested index.
  case exhausted
}
