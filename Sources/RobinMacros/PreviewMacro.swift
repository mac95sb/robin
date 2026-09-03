import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum PreviewMacroError: Error, CustomStringConvertible {
  case contentRequired

  var description: String { "Preview requires a trailing content closure" }
}

/// Implements RobinTesting's public `Preview` expression macro.
public struct PreviewMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard let closure = node.trailingClosure else { throw PreviewMacroError.contentRequired }
    return ExprSyntax("Preview(\(node.arguments)) \(closure)")
  }
}
