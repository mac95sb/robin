/// Marks a string-backed enum as a complete, typed set of custom color tokens.
@attached(extension, conformances: ColorTokenSetDefinition)
public macro ColorTokenSet() =
  #externalMacro(module: "RobinMacros", type: "ColorTokenSetMacro")
