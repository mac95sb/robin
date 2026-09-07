import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RobinMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    StateActionMacro.self, FieldNameMacro.self, ColorTokenSetMacro.self, PreviewMacro.self,
    FormModelMacro.self, ResourceMacro.self,
  ]
}
