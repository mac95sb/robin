import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum FieldNameMacroError: Error, CustomStringConvertible {
  case stringLiteralRequired

  var description: String { "generatedFieldName requires one plain string literal" }
}

/// Implements the public `generatedFieldName` expression macro.
public struct FieldNameMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard
      let expression = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
      expression.segments.count == 1,
      case .stringSegment(let segment)? = expression.segments.first
    else {
      throw FieldNameMacroError.stringLiteralRequired
    }
    return ExprSyntax(StringLiteralExprSyntax(content: "form.\(segment.content.text)"))
  }
}

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

@main
struct RobinMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [FieldNameMacro.self, ColorTokenSetMacro.self]
}
