import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Synthesizes the repetitive field operations for a declared form model.
public struct FormModelMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) else { throw FormModelError.structureRequired }
    let fields = try declaration.memberBlock.members.compactMap { member -> String? in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
        variable.attributes.contains(where: { attribute in
          attribute.as(AttributeSyntax.self)?.attributeName.trimmedDescription.split(separator: ".")
            .last == "Field"
        })
      else { return nil }
      guard variable.bindingSpecifier.tokenKind == .keyword(.var),
        !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
        variable.bindings.count == 1, let binding = variable.bindings.first,
        binding.initializer != nil,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
      else { throw FormModelError.fieldDeclarationRequired }
      return "_" + identifier.identifier.text
    }
    guard !fields.isEmpty else { throw FormModelError.fieldsRequired }
    let access =
      declaration.modifiers.contains { $0.name.tokenKind == .keyword(.public) } ? "public " : ""
    let decoding = fields.map { "\($0).decode(from: values)" }.joined(separator: "\n")
    let errors = fields.map { "\($0).validationError" }.joined(separator: ", ")
    return [
      """
      /// Applies submitted values to the declared fields.
      \(raw: access)mutating func decodeFields(from values: RobinForms.FormValues) {
        \(raw: decoding)
      }
      """,
      """
      /// The declared fields' validation errors in source order.
      \(raw: access)var validationErrors: [RobinForms.FieldValidationError] {
        [\(raw: errors)].compactMap { $0 }
      }
      """,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    [try ExtensionDeclSyntax("extension \(type.trimmed): RobinForms.Form {}")]
  }
}

private enum FormModelError: Error, CustomStringConvertible {
  case structureRequired, fieldsRequired
  case fieldDeclarationRequired
  var description: String {
    switch self {
    case .structureRequired: "FormModel requires a structure."
    case .fieldsRequired: "FormModel requires at least one @Field property with a default value."
    case .fieldDeclarationRequired:
      "Declare each form field as one instance var with a default value."
    }
  }
}
