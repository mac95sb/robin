import Testing

@testable import RobinStyling

@Suite("Condition lowering")
struct StyleConditionTests {
  @Test func hasConditionAppendsRelationalPseudoClassToTheGeneratedSelector() throws {
    let style = TypedStyle([.init(.display, "none")], condition: .has(".empty"))

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains(":has(.empty){display:none}"))
  }

  @Test func containerConditionLowersToAtContainerWithDeclaredContainment() throws {
    let style = TypedStyle(
      [.init(.display, "grid")],
      condition: .containerMinWidth(400),
      containmentContext: .declared
    )

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains("@container (min-width:400px){"))
  }

  @Test func containerConditionWithoutDeclaredContainmentThrows() {
    let style = TypedStyle([.init(.display, "grid")], condition: .containerMinWidth(400))

    #expect(throws: TypedCSSCompilerError.missingContainmentAncestor) {
      try TypedCSSCompiler.compile([style])
    }
  }

  @Test func pageConditionLowersToAtMediaRegardlessOfContainment() throws {
    let style = TypedStyle([.init(.display, "grid")], condition: .pageMinWidth(400))

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains("@media (min-width:400px){"))
  }

  @Test func sameDeclarationsUnderDifferentConditionsCompileToDifferentClasses() throws {
    let base = TypedStyle([.init(.display, "grid")])
    let has = TypedStyle([.init(.display, "grid")], condition: .has(".empty"))

    let result = try TypedCSSCompiler.compile([base, has])

    #expect(result.classNames[0] != result.classNames[1])
  }

  @Test(
    "Native open states lower without client runtime",
    arguments: [
      (StyleCondition.disclosureOpen, "[open]"),
      (StyleCondition.popoverOpen, ":popover-open"),
      (StyleCondition.dialogOpen, "[open]"),
    ]
  )
  func nativeOpenStateLowers(condition: StyleCondition, selector: String) throws {
    let style = TypedStyle([.init(.display, "block")], condition: condition)

    let result = try TypedCSSCompiler.compile([style])

    #expect(result.css.contains("\(selector){display:block}"))
  }
}
