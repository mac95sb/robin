import Foundation

/// An allowlisted email-safe component node.
public enum EmailComponent: Sendable {
  /// Escaped body text.
  case text(String, style: EmailTextStyle = .body)
  /// A safe absolute web link.
  case link(label: String, destination: URL)
  /// A vertical sequence of email components.
  case stack([EmailComponent])
  /// A deliberate line break.
  case lineBreak
}

/// Inline styles supported by the email renderer.
public enum EmailTextStyle: Sendable {
  /// Ordinary paragraph content.
  case body
  /// Primary heading content.
  case heading
  /// Secondary, visually muted content.
  case muted
}

/// Builds a sequence of email-safe components.
@resultBuilder
public struct EmailBuilder {
  private init() {}

  /// Combines component expressions.
  public static func buildBlock(_ components: EmailComponent...) -> EmailComponent {
    .stack(components)
  }

  /// Accepts a component expression.
  public static func buildExpression(_ component: EmailComponent) -> EmailComponent { component }

  /// Converts a string expression into safe text.
  public static func buildExpression(_ text: String) -> EmailComponent { .text(text) }
}

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

/// Email-template validation errors.
public enum EmailTemplateError: Error, Equatable, Sendable {
  /// Email links must use HTTP or HTTPS.
  case unsafeLink
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
