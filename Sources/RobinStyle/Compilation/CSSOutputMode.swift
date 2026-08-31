/// The whitespace formatting used when emitting a compiled stylesheet.
///
/// Output mode changes only the presentation of the emitted CSS. It does not
/// change style collection, token resolution, selector generation, or rule order.
public enum CSSOutputMode: Sendable {
  /// Emits readable CSS with spaces and line breaks.
  case development

  /// Emits compact CSS without optional spaces or line breaks.
  case production
}
