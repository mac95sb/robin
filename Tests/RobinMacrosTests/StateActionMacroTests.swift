import RobinMacros
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

@Suite("State action macro")
struct StateActionMacroTests {
  private func expand(_ source: String) throws -> String {
    let file = Parser.parse(source: source)
    let expression = try #require(file.statements.first?.item.as(MacroExpansionExprSyntax.self))
    return try StateActionMacro.expansion(of: expression, in: BasicMacroExpansionContext())
      .description
  }

  @Test func translatesTypedMutationsWithoutExecutingSwift() throws {
    let source = """
      #action {
        count += 10
        amount = 19.95
        name = "Robin"
        self.isHidden.toggle()
        copy = count + (count - 1)
        name += " Swift"
      }
      """
    let result = try expand(source)
    #expect(
      result.contains("$count.set(($count.expression + RobinRuntime.StateExpression.literal(10)))"))
    #expect(result.contains("$amount.set(RobinRuntime.StateExpression.literal(19.95))"))
    #expect(result.contains("self.$isHidden.toggle()"))
    #expect(result.contains("$copy.set("))
    #expect(result.contains("$name.expression +"))
  }

  @Test(arguments: [
    "#action { print(count) }",
    "#action { if count > 0 { count -= 1 } }",
    "#action { for _ in 0..<10 { count += 1 } }",
    "#action { let value = 10; count = value }",
    "#action { count = fetchValue() }",
    "#action { count *= 2 }",
    "#action { count = count * 2 }",
    "#action { value in count = value }",
    "#action { $count = 10 }",
    "#action { name = \"Hello \\(count)\" }",
  ])
  func rejectsUnsupportedSyntax(_ source: String) {
    #expect(throws: (any Error).self) { try expand(source) }
  }
}
