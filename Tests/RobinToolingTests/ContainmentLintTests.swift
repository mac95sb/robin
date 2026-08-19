import Testing

@testable import RobinTooling

@Suite("Containment lint")
struct ContainmentLintTests {
  @Test func diagnosesContainerConditionWithNoDeclaredContainmentAncestor() {
    let usages = [
      ComponentContainerUsage(
        componentName: "Card",
        usesContainerCondition: true,
        declaresContainmentAncestor: false
      )
    ]

    #expect(
      ContainmentLint.lint(usages) == [.missingContainmentAncestor(component: "Card")]
    )
  }

  @Test func allowsContainerConditionWithDeclaredContainmentAncestor() {
    let usages = [
      ComponentContainerUsage(
        componentName: "Card",
        usesContainerCondition: true,
        declaresContainmentAncestor: true
      )
    ]

    #expect(ContainmentLint.lint(usages).isEmpty)
  }

  @Test func ignoresComponentsThatDoNotUseContainerConditions() {
    let usages = [
      ComponentContainerUsage(
        componentName: "Text",
        usesContainerCondition: false,
        declaresContainmentAncestor: false
      )
    ]

    #expect(ContainmentLint.lint(usages).isEmpty)
  }
}
