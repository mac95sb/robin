import Crypto
import RobinCore

/// A normalized object key that cannot escape a storage namespace.
public struct ObjectKey: Hashable, Sendable {
  /// The normalized slash-separated value.
  public let value: String

  /// Creates a validated object key.
  public init(_ value: String) throws {
    let segments = value.split(separator: "/", omittingEmptySubsequences: false)
    guard !value.isEmpty, !value.hasPrefix("/"), !value.hasSuffix("/"),
      !value.contains("\\"), !value.contains("\0"),
      segments.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
    else { throw StorageError.invalidObjectKey(value) }
    self.value = segments.joined(separator: "/")
  }
}
