/// A structural error discovered while compiling typed styles.
public enum TypedCSSCompilerError: Error, Equatable, Sendable {
  /// A ``StyleCondition/containerMinWidth(_:)`` condition was compiled without a declared
  /// containment ancestor.
  case missingContainmentAncestor
}
