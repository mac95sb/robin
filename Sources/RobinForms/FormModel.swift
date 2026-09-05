/// Synthesizes form decoding and error collection from default-valued `@Field` properties.
///
/// The structure must provide a zero-argument initializer, normally synthesized from field defaults.
/// Field declarations remain the source for native constraints and server validation.
@attached(member, names: named(decodeFields), named(validationErrors))
@attached(extension, conformances: Form)
public macro FormModel() = #externalMacro(module: "RobinMacros", type: "FormModelMacro")
