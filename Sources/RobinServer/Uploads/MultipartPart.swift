/// One validated part of a multipart form upload.
public struct MultipartPart: Equatable, Sendable {
  /// The form field name.
  public let name: String
  /// The submitted filename for a file part.
  public let filename: String?
  /// Lowercased part-header names and their values.
  public let headers: [String: String]
  /// The unmodified part body.
  public let body: [UInt8]

  /// Creates a validated multipart part.
  public init(
    name: String,
    filename: String?,
    headers: [String: String],
    body: [UInt8]
  ) {
    self.name = name
    self.filename = filename
    self.headers = headers
    self.body = body
  }
}
