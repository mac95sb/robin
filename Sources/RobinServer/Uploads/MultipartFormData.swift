import Foundation
import HTTPTypes

/// A bounded multipart/form-data parser that preserves uploaded bytes exactly.
public struct MultipartFormData {
  /// Parses validated multipart form data from a complete request body.
  ///
  /// - Parameters:
  ///   - request: A request with a multipart content type and complete body.
  ///   - maximumParts: The positive maximum number of accepted parts.
  ///   - maximumPartBytes: The maximum bytes accepted in one part.
  /// - Returns: Parts in wire order.
  /// - Throws: ``MultipartError`` when validation fails.
  public static func parse(
    _ request: Request,
    maximumParts: Int = 100,
    maximumPartBytes: Int = 10_485_760
  ) throws -> [MultipartPart] {
    precondition(maximumParts > 0 && maximumPartBytes >= 0)
    guard let contentType = request.header(.contentType) else {
      throw MultipartError.contentTypeRequired
    }
    guard contentType.lowercased().hasPrefix("multipart/form-data") else {
      throw MultipartError.contentTypeRequired
    }
    guard let boundary = parameter("boundary", in: contentType), !boundary.isEmpty else {
      throw MultipartError.boundaryRequired
    }

    let body = request.body
    let firstBoundary = Array("--\(boundary)".utf8)
    let delimiter = Array("\r\n--\(boundary)".utf8)
    let headerSeparator: [UInt8] = [13, 10, 13, 10]
    guard body.starts(with: firstBoundary) else { throw MultipartError.malformed }
    var cursor = firstBoundary.count
    var parts: [MultipartPart] = []

    while true {
      if body[safe: cursor] == 45, body[safe: cursor + 1] == 45 { return parts }
      guard body[safe: cursor] == 13, body[safe: cursor + 1] == 10 else {
        throw MultipartError.malformed
      }
      cursor += 2
      guard let headerEnd = range(of: headerSeparator, in: body, from: cursor)?.lowerBound else {
        throw MultipartError.malformed
      }
      let headers = try parseHeaders(body[cursor..<headerEnd])
      let contentStart = headerEnd + headerSeparator.count
      guard let next = range(of: delimiter, in: body, from: contentStart) else {
        throw MultipartError.malformed
      }
      let content = Array(body[contentStart..<next.lowerBound])
      guard content.count <= maximumPartBytes else { throw MultipartError.partTooLarge }
      guard parts.count < maximumParts else { throw MultipartError.tooManyParts }
      guard let disposition = headers["content-disposition"],
        let name = parameter("name", in: disposition)
      else {
        throw MultipartError.malformed
      }
      parts.append(
        MultipartPart(
          name: name,
          filename: parameter("filename", in: disposition),
          headers: headers,
          body: content
        )
      )
      cursor = next.upperBound
    }
  }

  private static func parseHeaders(_ bytes: ArraySlice<UInt8>) throws -> [String: String] {
    guard let text = String(bytes: bytes, encoding: .utf8) else { throw MultipartError.malformed }
    var headers: [String: String] = [:]
    for line in text.components(separatedBy: "\r\n") {
      let pair = line.split(separator: ":", maxSplits: 1)
      guard pair.count == 2 else { throw MultipartError.malformed }
      headers[pair[0].lowercased()] = pair[1].trimmingCharacters(in: .whitespaces)
    }
    return headers
  }

  private static func parameter(_ name: String, in value: String) -> String? {
    value.split(separator: ";").dropFirst().lazy.compactMap { raw in
      let pair = raw.split(separator: "=", maxSplits: 1)
      guard pair.count == 2,
        pair[0].trimmingCharacters(in: .whitespaces).lowercased() == name.lowercased()
      else {
        return nil
      }
      return pair[1].trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }.first
  }

  private static func range(
    of needle: [UInt8],
    in bytes: [UInt8],
    from start: Int
  ) -> Range<Int>? {
    guard !needle.isEmpty, start <= bytes.count - needle.count else { return nil }
    for index in start...(bytes.count - needle.count)
    where bytes[index..<(index + needle.count)].elementsEqual(needle) {
      return index..<(index + needle.count)
    }
    return nil
  }
}

extension Array {
  fileprivate subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
