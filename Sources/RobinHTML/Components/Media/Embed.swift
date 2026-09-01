import Foundation

/// A sandboxed, origin-allowlisted third-party document.
public struct Embed: Component {
  public enum Sandbox: Equatable, Sendable {
    case strict
    case forms

    var value: String {
      switch self {
      case .strict: ""
      case .forms: "allow-forms"
      }
    }
  }

  public enum ValidationError: Error, Equatable, Sendable {
    case insecureSource
    case missingOrigin
    case originNotAllowed(String)
  }

  public let body: ComponentContent

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
