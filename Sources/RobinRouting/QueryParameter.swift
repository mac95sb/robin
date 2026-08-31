import Foundation

/// A typed query-value codec shared by matching and reverse routing.
public struct QueryParameter<Value: Sendable>: Sendable {
  public let name: String
  private let decodeValue: @Sendable (String) -> Value?
  private let encodeValue: @Sendable (Value) -> String

  public init(
    _ name: String,
    decode: @escaping @Sendable (String) -> Value?,
    encode: @escaping @Sendable (Value) -> String
  ) {
    self.name = name
    self.decodeValue = decode
    self.encodeValue = encode
  }

  public func value(in url: String) -> Value? {
    guard let components = URLComponents(string: url) else { return nil }
    guard let value = components.queryItems?.first(where: { $0.name == name })?.value else {
      return nil
    }
    return decodeValue(value)
  }

  public func appending(_ value: Value, to path: String) -> String {
    var components = URLComponents(string: path) ?? URLComponents()
    var items = components.queryItems ?? []
    items.removeAll { $0.name == name }
    items.append(URLQueryItem(name: name, value: encodeValue(value)))
    components.queryItems = items
    return components.string ?? path
  }
}

extension QueryParameter where Value == String {
  public static func string(_ name: String) -> Self { .init(name, decode: { $0 }, encode: { $0 }) }
}

extension QueryParameter where Value == Int {
  public static func integer(_ name: String) -> Self {
    .init(name, decode: Int.init, encode: String.init)
  }
}
