/// An unresolved theme token encountered during style compilation.
///
/// ``StyleCompiler/compile(_:theme:mode:)`` throws these errors on the first
/// missing token it encounters while resolving a unique normalized signature.
public enum ThemeError: Error, Equatable, Sendable {
  /// The applicable color palette does not contain the referenced token.
  case missingColor(ColorToken)

  /// The typography scale does not contain a referenced token.
  case missingTypography(TypographyToken)

  /// The spacing scale does not contain a referenced token.
  case missingSpacing(SpacingToken)

  /// The radius scale does not contain a referenced token.
  case missingRadius(RadiusToken)

  /// The breakpoint scale does not contain a referenced token.
  case missingBreakpoint(BreakpointToken)
  case missingShadow(ShadowToken)
  case invalidCondition(String)
  case missingContainmentAncestor
}
