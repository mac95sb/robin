import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Adds the typed color-token-set conformance to a string-backed enum.
public struct ColorTokenSetMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    [try ExtensionDeclSyntax("extension \(type.trimmed): ColorTokenSetDefinition {}")]
  }
}
