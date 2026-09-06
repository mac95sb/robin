import Foundation
@_spi(Rendering) import RobinBuild

extension Middleware {
  static var clientState: Self {
    Self { request, context, next in
      if request.path == ClientStateRuntime.path
        && (request.method == .get || request.method == .head)
      {
        let asset = try ClientStateRuntime.asset()
        return Response(
          headers: [.contentType: asset.mediaType], body: request.method == .head ? [] : asset.bytes
        )
      }
      return try await next.respond(to: request, context: context)
    }
  }
}
