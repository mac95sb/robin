/// A typed message body rendered for constrained email clients.
public struct EmailTemplate: Sendable {
  /// Root component.
  public let content: EmailComponent

  /// Creates an email template.
  public init(@EmailBuilder content: () -> EmailComponent) { self.content = content() }

  /// Renders the allowlisted HTML target with inline CSS.
  public func html() throws -> String {
    "<!doctype html><html><body style=\"margin:0;padding:24px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#111827\">\(try content.html)</body></html>"
  }

  /// Derives a deterministic plain-text alternative.
  public func plainText() -> String {
    content.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension EmailComponent {
  fileprivate var html: String {
    get throws {
      switch self {
      case .text(let value, let style):
        let declaration: String
        switch style {
        case .body: declaration = "margin:0 0 16px;font-size:16px;line-height:1.5"
        case .heading:
          declaration = "margin:0 0 16px;font-size:24px;line-height:1.25;font-weight:700"
        case .muted: declaration = "margin:0 0 16px;font-size:14px;line-height:1.5;color:#6b7280"
        }
        return "<p style=\"\(declaration)\">\(value.escapedHTML)</p>"
      case .link(let label, let destination):
        guard let scheme = destination.scheme?.lowercased(), scheme == "https" || scheme == "http"
        else { throw EmailTemplateError.unsafeLink }
        return
          "<a href=\"\(destination.absoluteString.escapedHTMLAttribute)\" style=\"color:#2563eb;text-decoration:underline\">\(label.escapedHTML)</a>"
      case .stack(let children):
        return try children.map { try $0.html }.joined()
      case .lineBreak:
        return "<br>"
      }
    }
  }

  fileprivate var plainText: String {
    switch self {
    case .text(let value, _): value + "\n\n"
    case .link(let label, let destination): "\(label) <\(destination.absoluteString)>\n\n"
    case .stack(let children): children.map(\.plainText).joined()
    case .lineBreak: "\n"
    }
  }
}

extension String {
  fileprivate var escapedHTML: String {
    replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }

  fileprivate var escapedHTMLAttribute: String {
    escapedHTML.replacingOccurrences(of: "\"", with: "&quot;")
  }
}
