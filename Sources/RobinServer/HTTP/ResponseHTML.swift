import Crypto
import Foundation
import HTTPTypes
import RobinBuild
import RobinCore
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle

extension Response {
  /// Renders typed content as a complete HTML document with metadata and compiled styles.
  ///
  /// The default security middleware allows the exact generated stylesheet through its CSP hash.
  /// Use this overload to redisplay a submitted form with a non-success status and accessible errors.
  public static func html(
    metadata: Metadata, theme: Theme = .default, status: HTTPResponse.Status = .ok,
    @ViewBuilder content: () -> ComponentContent
  ) throws -> Self {
    let root = RenderNode.fragment(content().nodes)
    let styles = try StyleCompiler.compile(root, theme: theme, mode: .development)
    let body = try HTMLRenderer.render(root, styles: styles.className(for:))
    let document = try BuildPipeline.serverDocument(body: body, metadata: metadata, css: styles.css)
    var response = Response.html(document, status: status)
    if !styles.css.isEmpty {
      response.compiledStyleHash =
        "sha256-\(Data(SHA256.hash(data: Array(styles.css.utf8))).base64EncodedString())"
    }
    return response
  }
}
