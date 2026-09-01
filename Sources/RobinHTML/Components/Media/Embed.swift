import Foundation

/// A sandboxed, origin-allowlisted third-party document.
public struct Embed: Component {
  /// The capabilities granted to embedded third-party content.
  public enum Sandbox: Equatable, Sendable {
    /// Grants no optional sandbox capabilities.
    case strict
    /// Allows the embedded document to submit forms.
    case forms

    var value: String {
      switch self {
      case .strict: ""
      case .forms: "allow-forms"
      }
    }
  }

  /// A rejected embed configuration.
  public enum ValidationError: Error, Equatable, Sendable {
    /// The source does not use HTTPS.
    case insecureSource
    /// The source has no host.
    case missingOrigin
    /// The source origin is absent from the allowlist.
    case originNotAllowed(String)
  }

  public let body: ComponentContent

  /// Creates an allowlisted, sandboxed embed.
  ///
  /// - Parameters:
  ///   - source: The HTTPS document URL.
  ///   - title: An accessible title for the embedded document.
  ///   - allowedOrigins: Exact HTTPS origins permitted to render.
  ///   - sandbox: The capabilities granted to the embedded document.
  /// - Throws: ``ValidationError`` when the source is insecure, lacks an origin, or is not allowed.
  public init(
    source: URL,
    title: String,
    allowedOrigins: Set<String>,
    sandbox: Sandbox = .strict
  ) throws {
    guard source.scheme == "https" else { throw ValidationError.insecureSource }
    guard let host = source.host else { throw ValidationError.missingOrigin }
    let origin = "https://\(host)" + (source.port.map { ":\($0)" } ?? "")
    guard allowedOrigins.contains(origin) else { throw ValidationError.originNotAllowed(origin) }
    body = .node(
      .element(
        RenderElement(
          kind: .iframe,
          attributes: [.source(source.absoluteString), .title(title), .sandbox(sandbox.value)]
        )
      )
    )
  }
}
