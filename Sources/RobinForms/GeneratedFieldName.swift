/// Produces a stable `form.`-prefixed name from a string literal.
///
/// - Parameter name: A plain string literal containing the field name.
/// - Returns: The field name prefixed with `form.`.
@freestanding(expression)
public macro generatedFieldName(_ name: String) -> String =
  #externalMacro(module: "RobinMacros", type: "FieldNameMacro")
