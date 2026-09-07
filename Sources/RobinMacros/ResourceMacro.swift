import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Synthesizes the request and decoding plumbing for a declared API resource.
public struct ResourceMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let resource = try resource(from: declaration)
    let access = accessModifier(for: declaration)
    let fields = resource.required.map { "\(access)let \($0.name): \($0.type)" }.joined(
      separator: "\n")
    return [
      """
      /// The client-supplied properties required to create this resource.
      \(raw: access)struct Create: Decodable, Sendable {
        \(raw: fields)
      }
      """
    ]
  }

  public static func expansion(
    of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let resource = try resource(from: declaration)
    let access = accessModifier(for: declaration)
    let arguments = resource.required.map { "\($0.name): create.\($0.name)" }.joined(
      separator: ", ")
    let cases = resource.properties.map(\.name).joined(separator: ", ")
    let values = resource.properties.map {
      "\($0.name): try values.decode(\($0.type).self, forKey: .\($0.name))"
    }.joined(separator: ",\n")
    return [
      try ExtensionDeclSyntax(
        """
        extension \(type.trimmed): RobinRouting.ResourceRepresentable {
          /// Creates this resource with server-created defaults.
          \(raw: access)init(create: Create) {
            self.init(\(raw: arguments))
          }

          private enum CodingKeys: String, CodingKey { case \(raw: cases) }

          \(raw: access)init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
              \(raw: values)
            )
          }
        }
        """
      )
    ]
  }
}

private func resource(from declaration: some DeclGroupSyntax) throws -> ResourceDescription {
  guard let structure = declaration.as(StructDeclSyntax.self) else {
    throw ResourceMacroError.structureRequired
  }
  guard
    structure.inheritanceClause?.inheritedTypes.contains(where: {
      $0.type.trimmedDescription == "Codable"
    }) == true
  else {
    throw ResourceMacroError.codableRequired
  }
  let properties = try structure.memberBlock.members.compactMap { member -> ResourceProperty? in
    guard let variable = member.decl.as(VariableDeclSyntax.self),
      !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
    else { return nil }
    guard variable.bindings.count == 1, let binding = variable.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
      let annotation = binding.typeAnnotation
    else { throw ResourceMacroError.propertyDeclarationRequired }
    return ResourceProperty(
      name: identifier.identifier.text,
      type: annotation.type.trimmedDescription,
      hasDefault: binding.initializer != nil
    )
  }
  guard !properties.isEmpty else { throw ResourceMacroError.propertiesRequired }
  return ResourceDescription(properties: properties)
}

private func accessModifier(for declaration: some DeclGroupSyntax) -> String {
  declaration.modifiers.contains { $0.name.tokenKind == .keyword(.public) } ? "public " : ""
}

private struct ResourceDescription {
  let properties: [ResourceProperty]
  var required: [ResourceProperty] { properties.filter { !$0.hasDefault } }
}

private struct ResourceProperty {
  let name: String
  let type: String
  let hasDefault: Bool
}

private enum ResourceMacroError: Error, CustomStringConvertible {
  case structureRequired, codableRequired, propertiesRequired, propertyDeclarationRequired

  var description: String {
    switch self {
    case .structureRequired: "Resource requires a structure."
    case .codableRequired: "Resource requires the structure to conform to Codable."
    case .propertiesRequired: "Resource requires at least one stored property."
    case .propertyDeclarationRequired:
      "Declare each resource property as one typed instance property."
    }
  }
}
