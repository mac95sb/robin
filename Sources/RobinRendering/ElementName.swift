/// The set of HTML elements supported by Robin's render IR.
///
/// Each case maps to the HTML tag of the same name via its `rawValue`, which the
/// ``HTMLRenderer`` uses to emit markup. The set is intentionally small for the
/// validation milestone; extend it as the IR grows.
public enum ElementName: String, Sendable {
  case article, button, code, div, footer, form, h1, h2, header, iframe, input, li
  case main, nav, p, pre, section, span, table, tbody, td, th, thead, tr, ul
}
