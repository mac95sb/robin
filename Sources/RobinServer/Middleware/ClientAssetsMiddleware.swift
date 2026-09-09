import Foundation
import RobinBuild
import RobinHTML

extension Middleware {
  package static func clientAssets(_ assets: [BuildAsset]) -> Self {
    let scripts = assets.filter {
      $0.mediaType.lowercased().contains("javascript") && $0.scriptOrigin != nil
    }
    return Self { request, context, next in
      if request.method == .get || request.method == .head,
        let asset = assets.first(where: { $0.reference == request.path })
      {
        return Response(
          headers: [.contentType: asset.mediaType],
          body: request.method == .head ? [] : asset.bytes)
      }
      var response = try await next.respond(to: request, context: context)
      guard response.head.headerFields[.contentType]?.lowercased().contains("text/html") == true,
        let bytes = response.body.bufferedBytes,
        !scripts.isEmpty
      else { return response }
      let tags = scripts.map {
        "<script type=\"module\" src=\"\(HTMLRenderer.escape($0.reference))\"></script>"
      }.joined()
      var html = String(decoding: bytes, as: UTF8.self)
      if let closingBody = html.range(of: "</body>", options: .backwards) {
        html.insert(contentsOf: tags, at: closingBody.lowerBound)
      } else {
        html.append(tags)
      }
      response.body = .bytes(Array(html.utf8))
      response.head.headerFields[.contentLength] = String(html.utf8.count)
      return response
    }
  }
}
