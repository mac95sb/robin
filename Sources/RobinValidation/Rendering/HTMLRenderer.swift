import Foundation

public enum HTMLRenderer {
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

  public static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
