/// One component's use of a container condition, observed for containment linting.
public struct ComponentContainerUsage: Equatable, Sendable {
  /// The component's name, used to identify the diagnostic's source.
  public let componentName: String

  /// Whether the component conditions a style on a container query.
  public let usesContainerCondition: Bool

  /// Whether an ancestor in the component's composition declared typed containment
  /// (`.containerType(.inlineSize)`) for that condition to resolve against.
  public let declaresContainmentAncestor: Bool

  /// Creates a component's container-condition usage record.
  public init(
    componentName: String,
    usesContainerCondition: Bool,
    declaresContainmentAncestor: Bool
  ) {
    self.componentName = componentName
    self.usesContainerCondition = usesContainerCondition
    self.declaresContainmentAncestor = declaresContainmentAncestor
  }
}

/// A `robin lint` finding surfaced by ``ContainmentLint``.
public enum LintDiagnostic: Error, Equatable, Sendable {
  /// A component conditions a style on a container query with no declared containment ancestor.
  case missingContainmentAncestor(component: String)
}

/// Diagnoses component-level container conditions with no declared containment ancestor.
public enum ContainmentLint {
  /// Lints a set of observed component container-condition usages.
  ///
  /// - Parameter usages: The components to check, in any order.
  /// - Returns: A diagnostic for every component that conditions a style on a container query
  ///   without a declared containment ancestor, in input order.
  public static func lint(_ usages: [ComponentContainerUsage]) -> [LintDiagnostic] {
    usages
      .filter { $0.usesContainerCondition && !$0.declaresContainmentAncestor }
      .map { .missingContainmentAncestor(component: $0.componentName) }
  }
}
