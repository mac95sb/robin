import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Translates a bounded subset of Swift mutation syntax into typed state expressions.
public struct StateActionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard
      let closure = node.trailingClosure
        ?? node.arguments.first?.expression.as(ClosureExprSyntax.self),
      closure.signature == nil, node.additionalTrailingClosures.isEmpty,
      node.trailingClosure == nil ? node.arguments.count == 1 : node.arguments.isEmpty
    else { throw ActionError("Use #action { state = value } without parameters or captures.") }
    let actions = try closure.statements.map { item -> String in
      guard let expression = item.item.as(ExprSyntax.self) else {
        throw ActionError(
          "Actions support state assignments and toggle(), not declarations or control flow.")
      }
      if let call = expression.as(FunctionCallExprSyntax.self),
        let member = call.calledExpression.as(MemberAccessExprSyntax.self),
        member.declName.baseName.text == "toggle", let base = member.base,
        call.arguments.isEmpty, call.trailingClosure == nil, call.additionalTrailingClosures.isEmpty
      {
        return "\(try binding(base)).toggle()"
      }
      let parts: [ExprSyntax]
      if let infix = expression.as(InfixOperatorExprSyntax.self) {
        parts = [infix.leftOperand, infix.operator, infix.rightOperand]
      } else if let sequence = expression.as(SequenceExprSyntax.self) {
        parts = Array(sequence.elements)
      } else {
        throw ActionError("Use assignment, +=, -=, or Boolean toggle() in an action.")
      }
      guard parts.count >= 3 else { throw ActionError("A state mutation requires a value.") }
      let target = try binding(parts[0])
      let operation = parts[1].trimmedDescription
      guard ["=", "+=", "-="].contains(operation) else {
        throw ActionError("Actions support =, +=, and -= mutations.")
      }
      let value = try translate(Array(parts.dropFirst(2)))
      let rhs =
        operation == "="
        ? value : "(\(target).expression \(operation == "+=" ? "+" : "-") \(value))"
      return "\(target).set(\(rhs))"
    }
    return ExprSyntax("RobinRuntime.StateAction([\(raw: actions.joined(separator: ",\n"))])")
  }

  private static func binding(_ expression: ExprSyntax) throws -> String {
    if let name = expression.as(DeclReferenceExprSyntax.self), name.argumentNames == nil {
      let identifier = name.baseName.text
      guard identifier != "self", !identifier.hasPrefix("$") else {
        throw ActionError("Mutate the state value (count), not its projected binding ($count).")
      }
      return "$" + identifier
    }
    if let member = expression.as(MemberAccessExprSyntax.self),
      member.base?.trimmedDescription == "self", member.declName.argumentNames == nil
    {
      return "self.$" + member.declName.baseName.text
    }
    throw ActionError("Actions reference @State properties by name or self.name.")
  }

  private static func translate(_ parts: [ExprSyntax]) throws -> String {
    guard let first = parts.first, parts.count % 2 == 1 else {
      throw ActionError("Unsupported state expression.")
    }
    var result = try translate(first)
    for index in stride(from: 1, to: parts.count, by: 2) {
      let operation = parts[index].trimmedDescription
      guard operation == "+" || operation == "-" else {
        throw ActionError(
          "State expressions support +, -, and Boolean !; other operators are not yet supported.")
      }
      result = "(\(result) \(operation) \(try translate(parts[index + 1])))"
    }
    return result
  }

  private static func translate(_ expression: ExprSyntax) throws -> String {
    if expression.is(IntegerLiteralExprSyntax.self) || expression.is(FloatLiteralExprSyntax.self)
      || expression.is(BooleanLiteralExprSyntax.self)
    {
      return "RobinRuntime.StateExpression.literal(\(expression.trimmedDescription))"
    }
    if let string = expression.as(StringLiteralExprSyntax.self) {
      guard string.segments.allSatisfy({ $0.is(StringSegmentSyntax.self) }) else {
        throw ActionError(
          "Use string + concatenation in actions; interpolation is not yet supported.")
      }
      return "RobinRuntime.StateExpression.literal(\(string.trimmedDescription))"
    }
    if let sequence = expression.as(SequenceExprSyntax.self) {
      return try translate(Array(sequence.elements))
    }
    if let infix = expression.as(InfixOperatorExprSyntax.self) {
      return try translate([infix.leftOperand, infix.operator, infix.rightOperand])
    }
    if let tuple = expression.as(TupleExprSyntax.self), tuple.elements.count == 1,
      let element = tuple.elements.first, element.label == nil
    {
      return "(\(try translate(element.expression)))"
    }
    if let prefix = expression.as(PrefixOperatorExprSyntax.self) {
      if prefix.operator.text == "!" { return "(!\(try translate(prefix.expression)))" }
      if ["-", "+"].contains(prefix.operator.text),
        prefix.expression.is(IntegerLiteralExprSyntax.self)
          || prefix.expression.is(FloatLiteralExprSyntax.self)
      {
        return "RobinRuntime.StateExpression.literal(\(prefix.trimmedDescription))"
      }
      throw ActionError(
        "Only Boolean ! and signed numeric literals are supported prefix expressions.")
    }
    return "\(try binding(expression)).expression"
  }
}

private struct ActionError: Error, CustomStringConvertible {
  let description: String
  init(_ description: String) { self.description = description }
}
