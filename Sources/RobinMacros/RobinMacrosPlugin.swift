import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RobinMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    FieldNameMacro.self, ColorTokenSetMacro.self, PreviewMacro.self, FormModelMacro.self,
  ]
}
