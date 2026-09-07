/// Marks an API resource whose create request is synthesized from its required properties.
///
/// Apply ``Resource()`` to a `Codable & Sendable` structure. Its properties with defaults
/// belong to server-created responses; its required properties form the nested ``Create`` body
/// decoded by ``POST``.
public protocol ResourceRepresentable: Codable, Sendable {
  associatedtype Create: Decodable & Sendable

  /// Creates a complete resource from its client-supplied properties.
  init(create: Create)
}

/// Synthesizes an API resource's create body and complete response decoding.
///
/// Default-valued properties are created by the server. Required properties are decoded for
/// creation. Responses still decode every declared property, including server-created values.
@attached(member, names: named(Create))
@attached(
  extension,
  conformances: ResourceRepresentable,
  names: named(CodingKeys), named(init)
)
public macro Resource() = #externalMacro(module: "RobinMacros", type: "ResourceMacro")
