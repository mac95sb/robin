/// A validated mailbox address and optional display name.
public struct EmailAddress: Equatable, Sendable {
  /// RFC mailbox value used by the SMTP envelope and headers.
  public let address: String
  /// Optional human-readable display name.
  public let name: String?

  /// Creates an address that is safe to serialize in message headers.
  public init(_ address: String, name: String? = nil) throws {
    guard !address.contains(where: { $0 == "\r" || $0 == "\n" }),
      address.split(separator: "@").count == 2,
      !address.contains(" "),
      name?.contains(where: { $0 == "\r" || $0 == "\n" }) != true
    else { throw EmailError.invalidAddress }
    self.address = address
    self.name = name
  }

  package var header: String {
    guard let name else { return address }
    let escaped = name.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\" <\(address)>"
  }
}
