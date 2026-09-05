/// An uploaded file represented by its metadata and bytes.
public struct FileField: Codable, Equatable, Sendable {
  /// The client-supplied filename.
  public let filename: String
  /// The client-supplied media type.
  public let mediaType: String
  /// The complete uploaded file bytes.
  public let bytes: [UInt8]

  /// Creates an uploaded file value.
  ///
  /// - Parameters:
  ///   - filename: The client-supplied filename.
  ///   - mediaType: The client-supplied media type.
  ///   - bytes: The complete file bytes.
  public init(filename: String, mediaType: String, bytes: [UInt8]) {
    self.filename = filename
    self.mediaType = mediaType
    self.bytes = bytes
  }
}
