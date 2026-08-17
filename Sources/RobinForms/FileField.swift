/// An uploaded file represented by its metadata and bytes.
public struct FileField: Equatable, Sendable {
  public let filename: String
  public let mediaType: String
  public let bytes: [UInt8]

  public init(filename: String, mediaType: String, bytes: [UInt8]) {
    self.filename = filename
    self.mediaType = mediaType
    self.bytes = bytes
  }
}
