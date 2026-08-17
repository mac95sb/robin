import Foundation

/// Serializes a render tree to an HTML string.
///
/// The renderer escapes all text and attribute values, emits attributes in a
/// deterministic (name, value) order, and renders embeds as sandboxed iframes.
/// Validate trees with ``RenderValidator`` before rendering when the output is
/// user-facing.
public enum HTMLRenderer {
  /// Serializes a render tree to HTML.
  ///
  /// - Parameter node: The root of the render tree.
  /// - Returns: The serialized HTML. The output does not include a doctype.
  public static func render(_ node: RenderNode) -> String {
    switch node {
    case .text(let text):
      return escape(text)
    case .fragment(let children):
      return children.map(render).joined()
    case .embed(let embed):
      return
        #"<iframe sandbox="" src="\#(escape(embed.source))" title="\#(escape(embed.title))"></iframe>"#
    case .element(let element):
      let attributes = element.attributes.sorted {
        ($0.name, $0.value) < ($1.name, $1.value)
      }.map { #" \#($0.name)="\#(escape($0.value))""# }.joined()
      let children = element.children.map(render).joined()
      return "<\(element.name.rawValue)\(attributes)>\(children)</\(element.name.rawValue)>"
    }
  }

  /// Escapes HTML-significant characters in a string.
  ///
  /// Replaces `&`, `<`, `>`, and `"` with their entity equivalents. Apply to
  /// any value interpolated into markup.
  ///
  /// - Parameter value: The string to escape.
  /// - Returns: The escaped string, safe to embed in HTML text or attribute values.
  public static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
