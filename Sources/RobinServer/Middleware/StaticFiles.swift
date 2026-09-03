import Foundation
import HTTPTypes
import SystemPackage

extension Middleware {
  /// Serves files below one explicit root after application routes return 404.
  public static func staticFiles(root: URL) -> Self {
    let root = root.standardizedFileURL.resolvingSymlinksInPath()
    let rootPath = FilePath(root.path(percentEncoded: false))
    return Middleware(requiredCapabilities: .persistentFileSystem) { request, context, next in
      let response = try await next.respond(to: request, context: context)
      guard response.head.status == .notFound else { return response }
      guard ["GET", "HEAD"].contains(request.method.rawValue.uppercased()) else { return response }
      guard let relative = request.path.removingPercentEncoding else {
        return .text("Invalid path", status: .badRequest)
      }

      guard
        let resolved = rootPath.lexicallyResolving(
          FilePath(String(relative.drop(while: { $0 == "/" })))
        )
      else {
        return .text("Invalid path", status: .forbidden)
      }
      var candidate = URL(filePath: resolved.string)
      if (try? candidate.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
        candidate.appendPathComponent("index.html")
      }
      candidate = candidate.standardizedFileURL.resolvingSymlinksInPath()
      var candidatePath = FilePath(candidate.path(percentEncoded: false))
      guard candidatePath == rootPath || candidatePath.removePrefix(rootPath) else {
        return .text("Invalid path", status: .forbidden)
      }
      guard let size = try? candidate.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
        return response
      }

      return Response(
        headers: [
          .contentType: contentType(for: candidate.pathExtension),
          .contentLength: String(size),
        ],
        body: request.method == .head ? .bytes([]) : .file(candidate)
      )
    }
  }

  private static func contentType(for extensionName: String) -> String {
    switch extensionName.lowercased() {
    case "css": "text/css; charset=utf-8"
    case "html": "text/html; charset=utf-8"
    case "js": "text/javascript; charset=utf-8"
    case "json": "application/json"
    case "svg": "image/svg+xml"
    case "png": "image/png"
    case "jpg", "jpeg": "image/jpeg"
    case "webp": "image/webp"
    case "avif": "image/avif"
    case "woff2": "font/woff2"
    default: "application/octet-stream"
    }
  }
}
